#!/bin/bash
HD_DEV=''
BOOT_PART=''
ROOT_PART=''
SWAP_PART=''
CHROOT='/mnt'
SUCESS=0
FAILURE=1
# chosen locale
LOCALE=''
# set locale
SET_LOCALE='1'
# list locales
LIST_LOCALE='2'
# chosen keymap
KEYMAP=''
# set keymap
SET_KEYMAP='1'
# list keymaps
LIST_KEYMAP='2'
VERBOSE='/dev/stdout'
confirm()
{
  header="$1"
  ask="$2"
  while true
  do
    echo "$header"
    echo "$ask"
    read -r input
    case $input in
      y|Y|yes|YES|Yes) return $TRUE ;;
      n|N|no|NO|No) return $FALSE ;;
      *) clear ; continue ;;
    esac
  done
  return $SUCCESS
}

get_disks()
{
 echo "Disk Available"
diskout=$(fdisk -l | grep Disk |grep /dev |awk '{print $2}'|sed 's\:\\g')
echo -e "${RED}$diskout${RESET}"
echo -n "Choose a Disk: "
read disk

for output in $diskout
do
        if [ $disk = $output  ]
        then
                #echo "Valid Disk"
                HD_DEV=$disk
                break
        else
                continue
        fi
done

echo $HD_DEV
if [ -z $HD_DEV  ]
then
        echo "Invalid Disk"
        get_disks
else
        echo "Valid Disk"
fi
return $SUCESS
}

autopart()
{
	get_disks
	echo "Parting the boot disk"
	echo "Making GPT Partition(Default)..."
	/sbin/parted $HD_DEV mklabel gpt --script
	echo "Making Boot partition of 500MB..."
        /sbin/parted $HD_DEV mkpart bios_grub 0% 500MB --script
        /sbin/parted $HD_DEV set 1 bios_grub on --script
	echo "Making Swap Partition of 2GB..."
	/sbin/parted $HD_DEV mkpart primary linux-swap 500MB 2GB --script
	echo "Making Root Partition of Remaing space..."
	/sbin/parted $HD_DEV mkpart primary ext4 2GB 100% --script
	parted_disk=$(fdisk -l |grep $HD_DEV |awk '{print $1}' |grep -v Disk)
	echo "Disk Formed..."
	echo $parted_disk
	Disk_Per_line=$(echo $parted_disk |sed ':a;N;$!ba;s/\n/ /g')
	BOOT_PART=$(echo $Disk_Per_line |awk '{print $1}')
	SWAP_PART=$(echo $Disk_Per_line |awk '{print $2}')
	ROOT_PART=$(echo $Disk_Per_line |awk '{print $3}')
	BOOT_FS_TYPE='fat32'
	ROOT_FS_TYPE='ext4'
	echo "Formatiting the Partition..."
	mkfs.fat -F32 $BOOT_PART
	mkfs.ext4 $ROOT_PART
	mkswap $SWAP_PART
	echo "Turning SwapON..."
	swapon $SWAP_PART
	return $SUCCESS

}

mount_fs()
{
	echo "mounting root_part"
	mount $ROOT_PART $CHROOT
	echo "swap on"
	swapon $SWAP_PART
	return $SUCCESS
}

fstab_setup()
{
	mkdir $CHROOT/etc
	genfstab -U $CHROOT >> $CHROOT/etc/fstab
}

full_system_dump()
{
  rsync -aWx --human-readable --info=progress2 / $CHROOT
  sed -i 's/Storage=volatile/#Storage=auto/' ${CHROOT}/etc/systemd/journald.conf
  rm -rf "$CHROOT/etc/udev/rules.d/81-dhcpcd.rules"
  rm -rf "$CHROOT/etc/systemd/system/"{choose-mirror.service,pacman-init.service,etc-pacman.d-gnupg.mount,getty@tty1.service.d}
  rm -rf "$CHROOT/etc/resolv.conf"
  rm -rf "$CHROOT/etc/systemd/scripts/choose-mirror"
  rm -rf "$CHROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf"
  rm -rf "$CHROOT/root/"{.automated_script.sh,.zlogin}"
  rm -rf "$CHROOT/etc/mkinitcpio-archiso.conf"
  rm -rf "$CHROOT/etc/initcpio"
}

base_system()
{
     pacstrap /mnt base linux linux-firmware	
}

setup_locale()
{
  echo 'Base System Setup > Locale'
  echo  "[+] Setting up $LOCALE locale"
  printf "\n\n"
  sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" "$CHROOT/etc/locale.gen"
  sed -i "s/^#$LOCALE/$LOCALE/" "$CHROOT/etc/locale.gen"
  chroot $CHROOT locale-gen > $VERBOSE 2>&1
  echo "LANG=$LOCALE" > "$CHROOT/etc/locale.conf
  echo "KEYMAP=$KEYMAP" > "$CHROOT/etc/vconsole.conf"
  return $SUCCESS
}

setup_time()
{
  if confirm 'Base System Setup > Timezone' '[?] Default: UTC. Choose other timezone [y/n]: '
  then
    for t in $(timedatectl list-timezones)
    do
      echo "    > $t"
    done
    echo "\n[?] What is your (Zone/SubZone): "
    read -r timezone
    chroot $CHROOT ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime \
      > $VERBOSE 2>&1
    if [ $? -eq 1 ]
    then
      echo 'Do you live on Mars? Setting default time zone...'
      sleep 1
      default_time
    else
      echo "\n[+] Time zone setup correctly\n"
    fi
  else
    echo "\n[+] Setting up default time and timezone\n"
    sleep 1
    default_time
  fi
  printf "\n"
  return $SUCCESS
}

# default time and timezone

default_time()
{
  chroot $CHROOT ln -sf /usr/share/zoneinfo/UTC /etc/localtime > $VERBOSE 2>&1

  return $SUCCESS
}

#pacman_keyring
reinitialize_keyring()
{
  echo 'Base System Setup > Keyring Reinitialization'
  echo '[+] Reinitializing keyrings'
  printf "\n"

chroot $CHROOT "/bin/bash" <<EOF
pacman-key --init
pacman-key --populate archlinux
EOF

  chroot $CHROOT pacman -S --overwrite='*' --noconfirm archlinux-keyring \
    > $VERBOSE 2>&1

  return $SUCCESS
}

#system_upgrade
sys_upgrade()

{
	chroot $CHROOT pacman -Syu
}

#grub setup
grub_setup()
{
    echo "Grub setup"
    chroot $CHROOT pacman -S grub --noconfirm --overwrite='*' --needed \
        > $VERBOSE 2>&1
    sed -i 's/Arch/Cynux-Security/g' "$CHROOT/etc/default/grub"
    #sed -i 's/#GRUB_COLOR_/GRUB_COLOR_/g' "$CHROOT/etc/default/grub"
    chroot $CHROOT grub-install --target=i386-pc "$HD_DEV" > $VERBOSE 2>&1
    chroot $CHROOT grub-mkconfig -o /boot/grub/grub.cfg > $VERBOSE 2>&1
}

# mount /proc, /sys and /dev

setup_procsysdev()
{
  echo 'Base System Setup > Proc Sys Dev'
  echo '[+] Setting up /proc, /sys and /dev'
  printf "\n\n"
  mkdir -p "${CHROOT}/"{proc,sys,dev} > $VERBOSE 2>&1
  mount -t proc proc "$CHROOT/proc" > $VERBOSE 2>&1
  mount --rbind /sys "$CHROOT/sys" > $VERBOSE 2>&1
  mount --make-rslave "$CHROOT/sys" > $VERBOSE 2>&1
  mount --rbind /dev "$CHROOT/dev" > $VERBOSE 2>&1
  mount --make-rslave "$CHROOT/dev" > $VERBOSE 2>&1

  return $SUCCESS

}

setup_resolvconf()
{
  echo 'Base System Setup > Etc'
  echo '[+] Setting up /etc/resolv.conf'
  printf "\n\n"
  mkdir -p "$CHROOT/etc/" > $VERBOSE 2>&1
 # cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf" > $VERBOSE 2>&1
  cp -f /etc/resolv.conf "$CHROOT/etc/resolv.conf" > $VERBOSE 2>&1
  return $SUCCESS
}
#setup_resolvconf

main()
{
	autopart
	sleep 1
	mount_fs
	sleep 1
	fstab_setup
  sleep 1
  base_system
	sleep 1
	full_system_dump
	sleep 1
	setup_locale
	sleep 1
	setup_time
	sleep 1
	setup_procsysdev
	sleep 1
	reinitialize_keyring
	setup_resolvconf
  sleep 1
	grub_setup
}

main
