#!/usr/bin/env bash
#==============================================================================#
#                                                                      #
# Cynux installer - Official Installer for Cynux Security OS                   #
#                                                                              #
# Author : argenestel@protonmail.com                                           #
# Organization : CybSec                                                        #
#                                                                              #
#==============================================================================#

# Cynux Installer version
VERSION='0.1'

# path to cynux-installer
CIPATH='/usr/share/cynux-installer'

# true / false
TRUE=0
FALSE=1

# return codes
SUCCESS=0
FAILURE=1

#colors
WHITE="$(tput setaf 7)"
WHITEB="$(tput bold ; tput setaf 7)"
BLUE="$(tput setaf 4)"
BLUEB="$(tput bold ; tput setaf 4)"
CYAN="$(tput setaf 6)"
CYANB="$(tput bold ; tput setaf 6)"
GREEN="$(tput setaf 2)"
GREENB="$(tput bold ; tput setaf 2)"
RED="$(tput setaf 1)"
REDB="$(tput bold; tput setaf 1)"
YELLOW="$(tput setaf 3)"
YELLOWB="$(tput bold ; tput setaf 3)"
BLINK="$(tput blink)"
RESET="$(tput sgr0)"


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

# network interfaces
NET_IFS=''

# chosen network interface
NET_IF=''

# network configuration mode
NET_CONF_MODE=''

# network configuration modes
NET_CONF_AUTO='1'
NET_CONF_WLAN='2'
NET_CONF_MANUAL='3'
NET_CONF_SKIP='4'

# default ArchLinux repository URL
AR_REPO_URL='https://archlinux.surlyjake.com/archlinux/$repo/os/$arch'
AR_REPO_URL="$AR_REPO_URL http://mirrors.evowise.com/archlinux/\$repo/os/\$arch"
AR_REPO_URL="$AR_REPO_URL http://mirror.rackspace.com/archlinux/\$repo/os/\$arch"

# hostname
HOST_NAME=''

# host ipv4 address
HOST_IPV4=''

# gateway ipv4 address
GATEWAY=''

# subnet mask
SUBNETMASK=''

# broadcast address
BROADCAST=''

# nameserver address
NAMESERVER=''

# DualBoot flag
DUALBOOT=''

# avalable hard drive
HD_DEVS=''

# chosen hard drive device
HD_DEV=''

# Partitions
PARTITIONS=''

# partition label: gpt or dos
PART_LABEL=''

# boot partition
BOOT_PART=''

# root partition
ROOT_PART=''

# swap partition
SWAP_PART=''

# boot fs type - default: ext4
BOOT_FS_TYPE=''

# root fs type - default: ext4
ROOT_FS_TYPE=''

#chroot env for installation
CHROOT='/mnt'

# normal system user
NORMAL_USER=''

# wlan ssid
WLAN_SSID=''

# wlan passphrase
WLAN_PASSPHRASE=''

# check boot mode
BOOT_MODE=''

#verbose mode off: by default
VERBOSE='/dev/null'

# Exit on CTRL + c
ctrl_c() {
  err "Keyboard Interrupt detected, leaving..."
  exit $FAILURE
}

trap ctrl_c 2


# check exit status
check()
{
  es=$1
  func="$2"
  info="$3"

  if [ "$es" -ne 0 ]
  then
    echo
    warn "Something went wrong with $func. $info."
    sleep 5
  fi
}


# print formatted output
wprintf()
{
  formating="${1}"
  shift
  printf "%s$formating%s" "$WHITE" "$@" "$RESET"

  return $SUCCESS
}


# print warning
warn()
{
  echo -e "${YELLOW}[!] WARNING: $@${RESET}"

  return $SUCCESS
}


# print error and return failure
err()
{
  echo -e "${REDB}[-] ERROR: $@${RESET}"

  return $FAILURE
}

banner()
{
  columns="$(tput cols)"
  str=" Cynux Installer "
  version="v$VERSION"

  printf "${GREENB}%*s${RESET}\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '='

  echo "$str" |
  while IFS= read -r line
  do
    printf "%s%*s\n%s" "$CYANB" $(( (${#line} + columns) / 2)) \
      "$line" "$RESET"
  done
  echo "$version"|
  while IFS= read -r line
  do
      printf "%s%*s\n%s" "$REDB" $(( (${#line} + columns) / 2)) "$line" "$RESET" 
  done

  printf "${GREENB}%*s${RESET}\n\n\n" "${COLUMNS:-$(tput cols)}" | tr ' ' '='

  return $SUCCESS
}

# check boot mode
check_boot_mode()
{
  if [ "$(efivar --list 2> /dev/null)" ]
  then
     BOOT_MODE="uefi"
  fi

  return $SUCCESS
}

#sleep and clear
sleep_clear()
{
  sleep "$1"
  clear

  return $SUCCESS
}


# confirm user inputted yYnN
confirm()
{
  header="$1"
  ask="$2"

  while true
  do
    title "$header"
    wprintf "$ask"
    read -r input
    case $input in
      y|Y|yes|YES|Yes) return $TRUE ;;
      n|N|no|NO|No) return $FALSE ;;
      *) clear ; continue ;;
    esac
  done

  return $SUCCESS
}

# print menu title
title()
{
  banner
  printf "${CYAN}# %s${RESET}\n\n\n" "${@}"

  return "${SUCCESS}"
}


# check for environment issues
check_env()
{
  if [ -f '/var/lib/pacman/db.lck' ]
  then
    err 'pacman locked - Please remove /var/lib/pacman/db.lck'
  fi
}


# check user id
check_uid()
{
  if [ "$(id -u)" != '0' ]
  then
    err 'You Must be Root to run Cynux Installer!'
  fi

  return $SUCCESS
}

# ask for output mode
ask_output_mode()
{
  title 'Environment > Output Mode'
  wprintf '[+] Available output modes:'
  printf "\n
  1. Quiet (default)
  2. Verbose (output of command)\n\n"
  wprintf "[?] Make a choice: "
  read -r output_opt
  if [ "$output_opt" = 2 ]
  then
    VERBOSE='/dev/stdout'
  fi

  return $SUCCESS
}

ask_locale()
{
  while [ "$locale_opt" != "$SET_LOCALE" ] && \
    [ "$locale_opt" != "$LIST_LOCALE" ]
  do
    title 'Environment > Locale Setup'
    wprintf '[+] Available locale options:'
    printf "\n
  1. Set a locale
  2. List available locales\n\n"
    wprintf "[?] Make a choice: "
    read -r locale_opt
    if [ "$locale_opt" = "$SET_LOCALE" ]
    then
      break
    elif [ "$locale_opt" = "$LIST_LOCALE" ]
    then
      less /etc/locale.gen
      echo
    else
      clear
      continue
    fi
    clear
  done

  clear

  return $SUCCESS
}

# set locale to use
set_locale()
{
  title 'Environment > Locale Setup'
  wprintf '[?] Set locale [en_US.UTF-8]: '
  read -r LOCALE

  # default locale
  if [ -z "$LOCALE" ]
  then
    echo
    warn 'Setting default locale for you: en_US.UTF-8...'
    sleep 1
    LOCALE='en_US.UTF-8'
  fi
  localectl set-locale "LANG=$LOCALE"
  check $? 'setting locale'

  return $SUCCESS
}

# ask for keymap to use
ask_keymap()
{
  while [ "$keymap_opt" != "$SET_KEYMAP" ] && \
    [ "$keymap_opt" != "$LIST_KEYMAP" ]
  do
    title 'Environment > Keymap Setup'
    wprintf '[+] Available keymap options:'
    printf "\n
  1. Set a keymap
  2. List available keymaps\n\n"
    wprintf '[?] Make a choice: '
    read -r keymap_opt

    if [ "$keymap_opt" = "$SET_KEYMAP" ]
    then
      break
    elif [ "$keymap_opt" = "$LIST_KEYMAP" ]
    then
      localectl list-keymaps
      echo
    else
      clear
      continue
    fi
    clear
  done

  clear

  return $SUCCESS
}

# set keymap to use
set_keymap()
{
  title 'Environment > Keymap Setup'
  wprintf '[?] Set keymap [us]: '
  read -r KEYMAP

  # default keymap
  if [ -z "$KEYMAP" ]
  then
    echo
    warn 'Setting default keymap: us'
    sleep 1
    KEYMAP='us'
  fi
  localectl set-keymap --no-convert "$KEYMAP"
  loadkeys "$KEYMAP" > $VERBOSE 2>&1
  check $? 'setting keymap'

  return $SUCCESS
}

# enable multilib in pacman.conf if x86_64 present
enable_pacman_multilib()
{
  path="$1"

  if [ "$path" = 'chroot' ]
  then
    path="$CHROOT"
  else
    path=""
  fi

  title 'Pacman Setup > Multilib'

  if [ "$(uname -m)" = "x86_64" ]
  then
    wprintf '[+] Enabling multilib support'
    printf "\n\n"
    if grep -q "#\[multilib\]" "$path/etc/pacman.conf"
    then
      # it exists but commented
      sed -i '/\[multilib\]/{ s/^#//; n; s/^#//; }' "$path/etc/pacman.conf"
    elif ! grep -q "\[multilib\]" "$path/etc/pacman.conf"
    then
      # it does not exist at all
      printf "[multilib]\nInclude = /etc/pacman.d/mirrorlist\n" \
        >> "$path/etc/pacman.conf"
    fi
  fi

  return $SUCCESS
}


# enable color mode in pacman.conf
enable_pacman_color()
{
  path="$1"

  if [ "$path" = 'chroot' ]
  then
    path="$CHROOT"
  else
    path=""
  fi

  title 'Pacman Setup > Color'

  wprintf '[+] Enabling color mode'
  printf "\n\n"

  sed -i 's/^#Color/Color/' "$path/etc/pacman.conf"

  return $SUCCESS
}

# enable misc options in pacman.conf
enable_pacman_misc()
{
  path="$1"

  if [ "$path" = 'chroot' ]
  then
    path="$CHROOT"
  else
    path=""
  fi

  title 'Pacman Setup > Misc Options'

  wprintf '[+] Enabling DisableDownloadTimeout'
  printf "\n\n"
  sed -i '37a DisableDownloadTimeout' "$path/etc/pacman.conf"

  # put here more misc options if necessary

  return $SUCCESS
}


# update pacman package database
update_pkg_database()
{
  title 'Pacman Setup > Package Database'

  wprintf '[+] Updating pacman database'
  printf "\n\n"

  pacman -Syy --noconfirm > $VERBOSE 2>&1

  return $SUCCESS
}


# update pacman.conf and database
update_pacman()
{
  enable_pacman_multilib
  sleep_clear 1

  enable_pacman_color
  sleep_clear 1

  enable_pacman_misc
  sleep_clear 1

  update_pkg_database
  sleep_clear 1

  return $SUCCESS
}

# ask user for hostname
ask_hostname()
{
  while [ -z "$HOST_NAME" ]
  do
    title 'Network Setup > Hostname'
    wprintf '[?] Set your hostname: '
    read -r HOST_NAME
    if [ -z "$HOST_NAME" ]
    then
            echo "Do you want to keep hostname as cynux?(y for yes)"
            read -r cynux_hostname
            if [ $cynux_hostname=y ]
            then
                    HOST_NAME="cynux"
            fi
    fi      
  done

  return $SUCCESS
}

# get available network interfaces
get_net_ifs()
{
  NET_IFS="$(ip -o link show | awk -F': ' '{print $2}' |grep -v 'lo')"

  return $SUCCESS
}


# ask user for network interface
ask_net_if()
{
  while true
  do
    title 'Network Setup > Network Interface'
    wprintf '[+] Available network interfaces:'
    printf "\n\n"
    for i in $NET_IFS
    do
      echo "    > $i"
    done
    echo
    wprintf '[?] Please choose a network interface: '
    read -r NET_IF
    if echo "$NET_IFS" | grep "\<$NET_IF\>" > /dev/null
    then
      clear
      break
    fi
    clear
  done

  return $SUCCESS
}


# auto (dhcp) network interface configuration
net_conf_auto()
{
  opts='-h noleak -i noleak -v ,noleak -I noleak -t 10'

  title 'Network Setup > Network Configuration (auto)'
  wprintf "[+] Configuring network interface '$NET_IF' via DHCP: "
  printf "\n\n"

  dhcpcd "$opts" -i "$NET_IF" > $VERBOSE 2>&1

  return $SUCCESS
}


# check for internet connection
check_inet_conn()
{
  title 'Network Setup > Connection Check'
  wprintf '[+] Checking for Internet connection...'

  if ! curl -s https://www.google.com > $VERBOSE
  then
    err 'No Internet connection! Check your network (settings).'
    exit $FAILURE
  fi

}

# get available hard disks
get_hd_devs()
{
  HD_DEVS="$(lsblk | grep disk | awk '{print $1}')"

  return $SUCCESS
}


# ask user for device to format and setup
ask_hd_dev()
{
  while true
  do
    title 'Hard Drive Setup'

    wprintf '[+] Available hard drives for installation:'
    printf "\n\n"

    for i in $HD_DEVS
    do
      echo "    > ${i}"
    done
    echo
    wprintf '[?] Please choose a device: '
    read -r HD_DEV
    if echo "$HD_DEVS" | grep "\<$HD_DEV\>" > /dev/null
    then
      HD_DEV="/dev/$HD_DEV"
      clear
      break
    fi
    clear
  done


  return $SUCCESS
}

# get available partitions on hard drive
get_partitions()
{
  PARTITIONS=$(fdisk -l "${HD_DEV}" -o device,size,type | \
    grep "${HD_DEV}[[:alnum:]]" |awk '{print $1;}')

  return $SUCCESS
}


# ask user to create partitions using cfdisk
ask_cfdisk()
{
  if confirm 'Hard Drive Setup > Partitions' '[?] Create partitions with cfdisk (root and boot, optional swap) [y/n]: '
  then
    clear
    zero_part
  else
    echo
    warn 'No partitions chosed? Make sure you have them already configured.'
    get_partitions
  fi

  return $SUCCESS
}


# zero out partition if needed/chosen
zero_part()
{
  local zeroed_part=0;
  if confirm 'Hard Drive Setup' '[?] Start with an in-memory zeroed partition table [y/n]: '
  zeroed_part=1;
  then
    cfdisk -z "$HD_DEV"
    sync
  else
    cfdisk "$HD_DEV"
    sync
  fi
  get_partitions
  if [ ${#PARTITIONS[@]} -eq 0 ] && [ $zeroed_part -eq 1 ] ; then
    err 'You have not created partitions on your disk, make sure to write your changes before quiting cfdisk. Trying again...'
    zero_part
  fi
  if [ "$BOOT_MODE" = 'uefi' ] && ! fdisk -l "$HD_DEV" -o type | grep -i 'EFI' ; then
    err 'You are booting in UEFI mode but not EFI partition was created, make sure you select the "EFI System" type for your EFI partition.'
    zero_part
  fi
  return $SUCCESS
}


# get partition label
get_partition_label()
{
  PART_LABEL="$(fdisk -l "$HD_DEV" |grep "Disklabel" | awk '{print $3;}')"

  return $SUCCESS
}


# get partitions
ask_partitions()
{
  while [ "$BOOT_PART" = '' ] || \
    [ "$ROOT_PART" = '' ] || \
    [ "$BOOT_FS_TYPE" = '' ] || \
    [ "$ROOT_FS_TYPE" = '' ]
  do
    title 'Hard Drive Setup > Partitions'
    wprintf '[+] Created partitions:'
    printf "\n\n"

    fdisk -l "${HD_DEV}" -o device,size,type |grep "${HD_DEV}[[:alnum:]]"

    echo

    if [ "$BOOT_MODE" = 'uefi' ]  && [ "$PART_LABEL" = 'gpt' ]
    then
      while [ -z "$BOOT_PART" ]; do
        wprintf "[?] EFI System partition (${HD_DEV}X): "
        read -r BOOT_PART
        until [[ "$PARTITIONS" =~ $BOOT_PART ]]; do
          wprintf "[?] Your partition $BOOT_PART is not in the partitions list.\n"
          wprintf "[?] EFI System partition (${HD_DEV}X): "
          read -r BOOT_PART
        done
      done
      BOOT_FS_TYPE="fat32"
    else
      while [ -z "$BOOT_PART" ]; do
        wprintf "[?] Boot partition (${HD_DEV}X): "
        read -r BOOT_PART
        until [[ "$PARTITIONS" =~ $BOOT_PART ]]; do
          wprintf "[?] Your partition $BOOT_PART is not in the partitions list.\n"
          wprintf "[?] Boot partition (${HD_DEV}X): "
          read -r BOOT_PART
        done
      done
      wprintf '[?] Choose a filesystem to use in your boot partition (ext2, ext3, ext4)? (default: ext4): '
      read -r BOOT_FS_TYPE
      if [ -z "$BOOT_FS_TYPE" ]; then
        BOOT_FS_TYPE="ext4"
      fi
    fi
    while [ -z "$ROOT_PART" ]; do
      wprintf "[?] Root partition (${HD_DEV}X): "
      read -r ROOT_PART
      until [[ "$PARTITIONS" =~ $ROOT_PART ]]; do
          wprintf "[?] Your partition $ROOT_PART is not in the partitions list.\n"
          wprintf "[?] Root partition (${HD_DEV}X): "
          read -r ROOT_PART
      done
    done
    wprintf '[?] Choose a filesystem to use in your root partition (ext2, ext3, ext4, btrfs)? (default: ext4): '
    read -r ROOT_FS_TYPE
    if [ -z "$ROOT_FS_TYPE" ]; then
      ROOT_FS_TYPE="ext4"
    fi
    wprintf "[?] Swap partition (${HD_DEV}X - empty for none): "
    read -r SWAP_PART
    if [ -n "$SWAP_PART" ]; then
        until [[ "$PARTITIONS" =~ $SWAP_PART ]]; do
          wprintf "[?] Your partition $SWAP_PART is not in the partitions list.\n"
          wprintf "[?] Swap partition (${HD_DEV}X): "
          read -r SWAP_PART
        done
    fi

    if [ "$SWAP_PART" = '' ]
    then
      SWAP_PART='none'
    fi
    clear
  done

  return $SUCCESS
}

# print partitions and ask for confirmation
print_partitions()
{
  i=""

  while true
  do
    title 'Hard Drive Setup > Partitions'
    wprintf '[+] Current Partition table'
    printf "\n
  > /boot   : %s (%s)
  > /       : %s (%s)
  > swap    : %s (swap)
  \n" "$BOOT_PART" "$BOOT_FS_TYPE" \
      "$ROOT_PART" "$ROOT_FS_TYPE" \
      "$SWAP_PART"
    wprintf '[?] Partition table correct [y/n]: '
    read -r i
    if [ "$i" = 'y' ] || [ "$i" = 'Y' ]
    then
      clear
      break
    elif [ "$i" = 'n' ] || [ "$i" = 'N' ]
    then
      echo
      err 'Hard Drive Setup aborted.'
      exit $FAILURE
    else
      clear
      continue
    fi
    clear
  done

  return $SUCCESS
}


# ask user and get confirmation for formatting
ask_formatting()
{
  if confirm 'Hard Drive Setup > Partition Formatting' '[?] Formatting partitions. Are you sure? No crying afterwards? [y/n]: '
  then
    return $SUCCESS
  else
    echo
    err 'Seriously? No formatting no fun! Please format to continue or CTRL + c to cancel...'
    ask_formatting
  fi

}
# create swap partition
make_swap_partition()
{
  title 'Hard Drive Setup > Partition Creation (swap)'

  wprintf '[+] Creating SWAP partition'
  printf "\n\n"
  mkswap $SWAP_PART > $VERBOSE 2>&1 || { err 'Could not create filesystem'; exit $FAILURE; }

}


# make and format root partition
make_root_partition()
{
  
    title 'Hard Drive Setup > Partition Creation (root)'
    wprintf '[+] Creating ROOT partition'
    printf "\n\n"
    if [ "$ROOT_FS_TYPE" = 'btrfs' ]
    then
      mkfs.$ROOT_FS_TYPE -f "$ROOT_PART" > $VERBOSE 2>&1 ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    else
      mkfs.$ROOT_FS_TYPE -F "$ROOT_PART" > $VERBOSE 2>&1 ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    fi

  return $SUCCESS
}


# make and format boot partition
make_boot_partition()
{

  title 'Hard Drive Setup > Partition Creation (boot)'

  wprintf '[+] Creating BOOT partition'
  printf "\n\n"
  if [ "$BOOT_MODE" = 'uefi' ] && [ "$PART_LABEL" = 'gpt' ]
  then
    mkfs.fat -F32 "$BOOT_PART" > $VERBOSE 2>&1 ||
      { err 'Could not create filesystem'; exit $FAILURE; }
  else
    mkfs.$BOOT_FS_TYPE -F "$BOOT_PART" > $VERBOSE 2>&1 ||
      { err 'Could not create filesystem'; exit $FAILURE; }
  fi

  return $SUCCESS
}


# make and format partitions
make_partitions()
{
  make_boot_partition
  sleep_clear 1

  make_root_partition
  sleep_clear 1

  if [ "$SWAP_PART" != "none" ]
  then
    make_swap_partition
    sleep_clear 1
  fi

  return $SUCCESS
}


# mount filesystems
mount_filesystems()
{
  title 'Hard Drive Setup > Mount'

  wprintf '[+] Mounting filesystems'
  printf "\n\n"

  # ROOT
    if ! mount "$ROOT_PART" $CHROOT; then
      err "Error mounting root filesystem, leaving."
      exit $FAILURE
    fi

  # BOOT
  mkdir "$CHROOT/boot" > $VERBOSE 2>&1
  if ! mount "$BOOT_PART" "$CHROOT/boot"; then
    err "Error mounting boot partition, leaving."
    exit $FAILURE
  fi

  # SWAP
  if [ "$SWAP_PART" != "none" ]
  then
    swapon $SWAP_PART > $VERBOSE 2>&1
  fi

  return $SUCCESS
}

# unmount filesystems
umount_filesystems()
{
  routine="$1"

  if [ "$routine" = 'harddrive' ]
  then
    title 'Hard Drive Setup > Unmount'

    wprintf '[+] Unmounting filesystems'
    printf "\n\n"

    umount -Rf /mnt > /dev/null 2>&1; \
    umount -Rf "$HD_DEV"{1..128} > /dev/null 2>&1 # gpt max - 128
    swapoff $SWAP_PART > /dev/null 2>&1
  fi

  return $SUCCESS
}

# check for necessary space
check_space()
{
    avail_space=$(df -m | grep "$ROOT_PART" | awk '{print $4}')

  if [ "$avail_space" -le 20000 ]
  then
    warn 'Cynux requires at least 20 GB of free space to install!'
  fi

  return $SUCCESS
}


# install ArchLinux base and base-devel packages
install_base_packages()
{
  title 'Base System Setup > ArchLinux Packages'

  wprintf '[+] Installing ArchLinux base packages'
  printf "\n\n"
  warn 'This can take a while, please wait...'
  printf "\n"

  pacstrap $CHROOT base base-devel btrfs-progs linux linux-firmware \
    terminus-font terminus-font-ttf > $VERBOSE 2>&1
  chroot $CHROOT pacman -Syy --noconfirm --overwrite='*' > $VERBOSE 2>&1
  
  return $SUCCESS
}

# setup /etc/resolv.conf
setup_resolvconf()
{
  title 'Base System Setup > Etc'

  wprintf '[+] Setting up /etc/resolv.conf'
  printf "\n\n"

  mkdir -p "$CHROOT/etc/" > $VERBOSE 2>&1
 # cp -L /etc/resolv.conf "$CHROOT/etc/resolv.conf" > $VERBOSE 2>&1
  cp -f /etc/resolv.conf "$CHROOT/etc/resolv.conf" > $VERBOSE 2>&1
  return $SUCCESS
}

add_resolv()
{
    title 'Adding Resolv.conf'
    
    wprintf '[+] Adding resolv.conf'
    chroot $CHROOT 'rm /etc/resolv.conf'
    chroot $CHROOT 'touch /etc/resolv.conf'
    chroot $CHROOT "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
    if ! ping -c 1 google.com
    then
         add_resolv
    fi
}

# setup fstab
setup_fstab()
{
  title 'Base System Setup > Etc'

  wprintf '[+] Setting up /etc/fstab'
  printf "\n\n"

  if [ "$PART_LABEL" = "gpt" ]
  then
    genfstab -U $CHROOT >> "$CHROOT/etc/fstab"
  else
    genfstab -L $CHROOT >> "$CHROOT/etc/fstab"
  fi

  sed 's/relatime/noatime/g' -i "$CHROOT/etc/fstab"

  return $SUCCESS
}

# setup locale and keymap
setup_locale()
{
  title 'Base System Setup > Locale'

  wprintf "[+] Setting up $LOCALE locale"
  printf "\n\n"
  sed -i "s/^#en_US.UTF-8/en_US.UTF-8/" "$CHROOT/etc/locale.gen"
  sed -i "s/^#$LOCALE/$LOCALE/" "$CHROOT/etc/locale.gen"
  chroot $CHROOT locale-gen > $VERBOSE 2>&1
  echo "LANG=$LOCALE" > "$CHROOT/etc/locale.conf"
  echo "KEYMAP=$KEYMAP" > "$CHROOT/etc/vconsole.conf"

  return $SUCCESS
}


# setup timezone
setup_time()
{
  if confirm 'Base System Setup > Timezone' '[?] Default: UTC. Choose other timezone [y/n]: '
  then
    for t in $(timedatectl list-timezones)
    do
      echo "    > $t"
    done

    wprintf "\n[?] What is your (Zone/SubZone): "
    read -r timezone
    chroot $CHROOT ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime \
      > $VERBOSE 2>&1

    if [ $? -eq 1 ]
    then
      warn 'Do you live on Mars? Setting default time zone...'
      sleep 1
      default_time
    else
      wprintf "\n[+] Time zone setup correctly\n"
    fi
  else
    wprintf "\n[+] Setting up default time and timezone\n"
    sleep 2
    default_time
  fi

  printf "\n"

  return $SUCCESS
}


# default time and timezone
default_time()
{
  echo
  warn 'Setting up default time and timezone: UTC'
  printf "\n\n"
  chroot $CHROOT ln -sf /usr/share/zoneinfo/UTC /etc/localtime > $VERBOSE 2>&1

  return $SUCCESS
}


setup_initramfs()
{
  title 'Base System Setup > InitramFS'

  wprintf '[+] Setting up InitramFS'
  printf "\n\n"

  cp -f "/etc/mkinitcpio.conf" "$CHROOT/etc/mkinitcpio.conf"
  cp -fr "/etc/mkinitcpio.d" "$CHROOT/etc/"

  cp /run/archiso/bootmnt/arch/boot/x86_64/vmlinuz-linux \
      "$CHROOT/boot/vmlinuz-linux"

  # terminus font
  sed -i 's/keyboard fsck/keyboard fsck consolefont/g' \
    "$CHROOT/etc/mkinitcpio.conf"
  echo 'FONT=ter-114n' >> "$CHROOT/etc/vconsole.conf"
  
  warn 'This can take a while, please wait...'
  printf "\n"
  chroot $CHROOT mkinitcpio -P > $VERBOSE 2>&1

  return $SUCCESS
}



# mount /proc, /sys and /dev
setup_proc_sys_dev()
{
  title 'Base System Setup > Proc Sys Dev'

  wprintf '[+] Setting up /proc, /sys and /dev'
  printf "\n\n"

  mkdir -p "${CHROOT}/"{proc,sys,dev} > $VERBOSE 2>&1

  mount -t proc proc "$CHROOT/proc" > $VERBOSE 2>&1
  mount --rbind /sys "$CHROOT/sys" > $VERBOSE 2>&1
  mount --make-rslave "$CHROOT/sys" > $VERBOSE 2>&1
  mount --rbind /dev "$CHROOT/dev" > $VERBOSE 2>&1
  mount --make-rslave "$CHROOT/dev" > $VERBOSE 2>&1

  return $SUCCESS
}


# setup hostname
setup_hostname()
{
  title 'Base System Setup > Hostname'

  wprintf '[+] Setting up hostname'
  printf "\n\n"

  echo "$HOST_NAME" > "$CHROOT/etc/hostname"

  return $SUCCESS
}

# setup boot loader for UEFI/GPT or BIOS/MBR
setup_bootloader()
{
  title 'Base System Setup > Boot Loader'

  if [ "$BOOT_MODE" = 'uefi' ] && [ "$PART_LABEL" = 'gpt' ]
  then
    wprintf '[+] Setting up EFI boot loader'
    printf "\n\n"

    chroot $CHROOT bootctl install > $VERBOSE 2>&1
    uuid="$(blkid "$ROOT_PART" | cut -d ' ' -f 2 | cut -d '"' -f 2)"

      cat >> "$CHROOT/boot/loader/entries/arch.conf" << EOF
title   Cynux Security
linux   /vmlinuz-linux
initrd    /initramfs-linux.img
options   root=UUID=$uuid rw
EOF
  else
    wprintf '[+] Setting up GRUB boot loader'
    printf "\n\n"

    uuid="$(lsblk -o UUID "$ROOT_PART" | sed -n 2p)"

      chroot $CHROOT pacman -S grub --noconfirm --overwrite='*' --needed \
        > $VERBOSE 2>&1

    if [ $DUALBOOT = $TRUE ]
    then
      chroot $CHROOT pacman -S os-prober --noconfirm --overwrite='*' --needed \
        > $VERBOSE 2>&1
    fi

    sed -i 's/Arch/Cynux-Security/g' "$CHROOT/etc/default/grub"

    sed -i 's/#GRUB_COLOR_/GRUB_COLOR_/g' "$CHROOT/etc/default/grub"

    chroot $CHROOT grub-install --target=i386-pc "$HD_DEV" > $VERBOSE 2>&1

    chroot $CHROOT grub-mkconfig -o /boot/grub/grub.cfg > $VERBOSE 2>&1

  fi

  return $SUCCESS
}

# ask for normal user account to setup
ask_user_account()
{
  if confirm 'Base System Setup > User' '[?] Setup a normal user account [y/n]: '
  then
    wprintf '[?] User name: '
    read -r NORMAL_USER
  else
          echo "User Cynux will be default user"
          NORMAL_USER='cynux'
  fi

  return $SUCCESS
}

setup_user()
{
  user="$(echo "$1" | tr -dc '[:alnum:]_' | tr '[:upper:]' '[:lower:]' |
    cut -c 1-32)"

  title 'Base System Setup > User'

  wprintf "[+] Setting up $user account"
  printf "\n\n"

  # normal user
  if [ -n "$NORMAL_USER" ]
  then
    chroot $CHROOT groupadd "$user" > $VERBOSE 2>&1
    chroot $CHROOT useradd -g "$user" -d "/home/$user" -s "/bin/bash" \
      -G "$user,wheel,users,video,audio" -m "$user" > $VERBOSE 2>&1
    chroot $CHROOT chown -R "$user":"$user" "/home/$user" > $VERBOSE 2>&1
    wprintf "[+] Added user: $user"
    printf "\n\n"
  # environment
  elif [ -z "$NORMAL_USER" ]
  then
    cp -r "/root/." "$CHROOT/root/." > $VERBOSE 2>&1
  else
    cp -r "/home/cynux/." "$CHROOT/home/$user/." > $VERBOSE 2>&1
    chroot $CHROOT chown -R "$user":"$user" "/home/$user" > $VERBOSE 2>&1
  fi

  # password
  res=1337
  wprintf "[?] Set password for $user: "
  printf "\n\n"
  while [ $res -ne 0 ]
  do
    if [ "$user" = "root" ]
    then
      chroot $CHROOT passwd
    else
      chroot $CHROOT passwd "$user"
    fi
    res=$?
  done

  return $SUCCESS
}

reinitialize_keyring()
{
  title 'Base System Setup > Keyring Reinitialization'

  wprintf '[+] Reinitializing keyrings'
  printf "\n"
  sleep 2

  chroot $CHROOT pacman -S --overwrite='*' --noconfirm archlinux-keyring \
    > $VERBOSE 2>&1

  return $SUCCESS
}

# install extra (missing) packages
setup_extra_packages()
{
  arch='arch-install-scripts pkgfile'

  bluetooth='bluez bluez-hid2hci bluez-tools bluez-utils'

  browser='chromium elinks firefox'

  editor='hexedit nano vim'

  filesystem='cifs-utils dmraid dosfstools exfat-utils f2fs-tools
  gpart gptfdisk mtools nilfs-utils ntfs-3g partclone parted partimage'

  fonts='ttf-dejavu ttf-indic-otf ttf-liberation xorg-fonts-misc'

  hardware='amd-ucode intel-ucode'

  kernel='linux-headers'

  misc='acpi alsa-utils b43-fwcutter bash-completion bc cmake ctags expac
  feh git gpm haveged hdparm htop inotify-tools ipython irssi
  linux-atm lsof mercurial mesa mlocate moreutils mpv p7zip rsync
  rtorrent screen scrot smartmontools strace tmux udisks2 unace unrar
  unzip upower usb_modeswitch usbutils zip zsh'

  network='atftp bind-tools bridge-utils curl darkhttpd dhclient dhcpcd dialog
  dnscrypt-proxy dnsmasq dnsutils fwbuilder gnu-netcat ipw2100-fw ipw2200-fw iw
  iwd lftp nfs-utils ntp openconnect openssh openvpn ppp pptpclient rfkill
  rp-pppoe socat vpnc wget wireless_tools wpa_supplicant wvdial xl2tpd'

  xorg='rxvt-unicode xf86-video-amdgpu xf86-video-ati
  xf86-video-dummy xf86-video-fbdev xf86-video-intel xf86-video-nouveau
  xf86-video-openchrome xf86-video-sisusb xf86-video-vesa xf86-video-vmware
  xf86-video-voodoo xorg-server xorg-xbacklight xorg-xinit xterm'

  all="$arch $bluetooth $browser $editor $filesystem $fonts $hardware $kernel"
  all="$all $misc $network $xorg"

  title 'Base System Setup > Extra Packages'

  wprintf '[+] Installing extra packages'
  printf "\n"

  printf "
  > ArchLinux   : $(echo "$arch" | wc -w) packages
  > Browser     : $(echo "$browser" | wc -w) packages
  > Bluetooth   : $(echo "$bluetooth" | wc -w) packages
  > Editor      : $(echo "$editor" | wc -w) packages
  > Filesystem  : $(echo "$filesystem" | wc -w) packages
  > Fonts       : $(echo "$fonts" | wc -w) packages
  > Hardware    : $(echo "$hardware" | wc -w) packages
  > Kernel      : $(echo "$kernel" | wc -w) packages
  > Misc        : $(echo "$misc" | wc -w) packages
  > Network     : $(echo "$network" | wc -w) packages
  > Xorg        : $(echo "$xorg" | wc -w) packages
  \n"

  warn 'This can take a while, please wait...'
  printf "\n"
  sleep 2

  chroot $CHROOT pacman -S --needed --overwrite='*' --noconfirm $all \
    > $VERBOSE 2>&1

  return $SUCCESS
}


# perform system base setup/configurations
setup_base_system()
{
    dump_full_iso
    sleep_clear 1
    add_resolv
    pass_mirror_conf # copy mirror list to chroot env

    setup_resolvconf    
    sleep_clear 1
    install_base_packages
    sleep_clear 1
    
    sleep_clear 0
    setup_resolvconf
    sleep_clear 1
    
  setup_fstab
  sleep_clear 1

  setup_proc_sys_dev
  sleep_clear 1

  setup_locale
  sleep_clear 1

  setup_initramfs
  sleep_clear 1

  setup_hostname
  sleep_clear 1

  setup_user "root"
  sleep_clear 1

  ask_user_account
  sleep_clear 1

  if [ -n "$NORMAL_USER" ]
  then
    setup_user "$NORMAL_USER"
    sleep_clear 1
  else
    setup_testuser
    sleep_clear 2
  fi
    reinitialize_keyring
    sleep_clear 1
    setup_extra_packages
    sleep_clear 1
  setup_bootloader
  sleep_clear 1

  return $SUCCESS
}

enable_iwd_networkd()
{
  title 'Cynux Setup > Network'

  wprintf '[+] Enabling Iwd and Networkd'
  printf "\n\n"

  chroot $CHROOT systemctl enable iwd systemd-networkd > $VERBOSE 2>&1

  return $SUCCESS
}

# update /etc files and set up iptables
update_etc()
{
  title 'Cynux Security Linux Setup > Etc files'

  wprintf '[+] Updating /etc files'
  printf "\n\n"

  # /etc/*
  cp -r "/etc/"{arch-release,issue,motd,\
os-release,sysctl.d,systemd} "$CHROOT/etc/." > $VERBOSE 2>&1

  return $SUCCESS
}

ask_mirror_arch()
{
  local mirrold='cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup'

  if confirm 'Pacman Setup > ArchLinux Mirrorlist' \
    "[+] Worldwide mirror will be used\n\n[?] Look for the best server [y/n]: "
  then
    printf "\n"
    warn 'This may take time depending on your connection'
    printf "\n"
    $mirrold
    pacman -Sy --noconfirm > $VERBOSE 2>&1
    pacman -S --needed --noconfirm reflector > $VERBOSE 2>&1
    yes | pacman -Scc > $VERBOSE 2>&1
    reflector --verbose --latest 10 --protocol https --sort rate \
      --save /etc/pacman.d/mirrorlist > $VERBOSE 2>&1
  else
    printf "\n"
    warn 'Using Worldwide mirror server'
    $mirrold
    echo -e "## Arch Linux repository Worldwide mirrorlist\n\n" \
      > /etc/pacman.d/mirrorlist

    for wore in $AR_REPO_URL
    do
      echo "Server = $wore" >> /etc/pacman.d/mirrorlist      
    done
    
  fi

}


pacman_keyring()
{
    
chroot $CHROOT "pacman-key --init"
chroot $CHROOT "pacman-key --populate archlinux"
chroot $CHROOT "pacman-key --refresh-keys"
}
# pass correct config
pass_mirror_conf()
{
  mkdir -p "$CHROOT/etc/pacman.d/" > $VERBOSE 2>&1
  cp -f /etc/pacman.d/mirrorlist "$CHROOT/etc/pacman.d/mirrorlist" \
    > $VERBOSE 2>&1
}

# setup display manager
setup_display_manager()
{
  title 'Cynux Linux Setup > Display Manager'

  wprintf '[+] Setting up GDM'
  printf "\n\n"

  # install gdm packages
  chroot $CHROOT pacman -Sy gdm --needed --overwrite='*' --noconfirm \
    > $VERBOSE 2>&1

  # config files
  cp -r "/etc/gdm/." "/etc/gdm/."
  cp -r "/usr/share/gdm/." "$CHROOT/usr/share/gdm/."
  cp -r "/usr/share/gtk-2.0/." "$CHROOT/usr/share/gtk-2.0/."
  mkdir -p "$CHROOT/usr/share/xsessions"

  # enable in systemd
  chroot $CHROOT systemctl enable gdm > $VERBOSE 2>&1

  return $SUCCESS
}



gnome_setup()
{
        #installing gnome desktop env
        chroot $CHROOT pacman -S gnome --needed --overwrite='*' --noconfirm > $VERBOSE 2>&1
        cp -r "/home/cynux/." "/home/$user/."
}

# ask user for VirtualBox modules+utils setup
ask_vbox_setup()
{
  if confirm 'Cynux Security Linux Setup > VirtualBox' '[?] Setup VirtualBox modules [y/n]: '
  then
    VBOX_SETUP=$TRUE
  fi

  return $SUCCESS
}

# setup virtualbox utils
setup_vbox_utils()
{
  title 'Cynux Security Linux Setup > VirtualBox'

  wprintf '[+] Setting up VirtualBox utils'
  printf "\n\n"

  chroot $CHROOT pacman -S virtualbox-guest-utils --overwrite='*' --needed \
    --noconfirm > $VERBOSE 2>&1

  chroot $CHROOT systemctl enable vboxservice > $VERBOSE 2>&1

  return $SUCCESS
}

# ask user for VirtualBox modules+utils setup
ask_vmware_setup()
{
  if confirm 'Cynux Security Linux Setup > VMware' '[?] Setup VMware modules [y/n]: '
  then
    VMWARE_SETUP=$TRUE
  fi

  return $SUCCESS
}


# setup vmware utils
setup_vmware_utils()
{
  title 'Cynux Security Linux Setup > VMware'

  wprintf '[+] Setting up VMware utils'
  printf "\n\n"

  chroot $CHROOT pacman -Sy open-vm-tools xf86-video-vmware \
    xf86-input-vmmouse --overwrite='*' --needed --noconfirm \
    > $VERBOSE 2>&1

  chroot $CHROOT systemctl enable vmware-vmblock-fuse.service > $VERBOSE 2>&1
  chroot $CHROOT systemctl enable vmtoolsd.service > $VERBOSE 2>&1

  return $SUCCESS
}

# add user to newly created groups
update_user_groups()
{
  title 'Cynux Setup > User'

  wprintf "[+] Adding user $user to groups and sudoers"
  printf "\n\n"

  #TODO: more to add here
  if [ $VBOX_SETUP -eq $TRUE ]
  then
    chroot $CHROOT usermod -aG 'vboxsf,audio,video' "$user" > $VERBOSE 2>&1
  fi

  # sudoers
  echo "$user ALL=(ALL) ALL" >> $CHROOT/etc/sudoers > $VERBOSE 2>&1

  return $SUCCESS
}

dump_full_iso()
{
  full_dirs='/bin /sbin /etc /home /lib /lib64 /opt /root /srv /usr /var /tmp'
  total_size=0 # no cheat

  title 'Cynux Linux Linux Setup'

  wprintf '[+] Dumping data from Full-ISO. Grab a coffee and pop shells!'
  printf "\n\n"

  wprintf '[+] Fetching total size to transfer, please wait...'
  printf "\n"

  for d in $full_dirs
  do
    part_size=$(du -sm "$d" 2> /dev/null | awk '{print $1}')
    ((total_size+=part_size))
    printf "
  > $d $part_size MB"
  done
  printf "\n
  [ Total size = $total_size MB ]
  \n\n"

  check_space

  wprintf '[+] Installing the backdoors to /'
  printf "\n\n"
  warn 'This can take a while, please wait...'
  printf "\n"
  rsync -aWx --human-readable --info=progress2 / $CHROOT > $VERBOSE 2>&1
  wprintf "[+] Installation done!\n"

  # clean up files
  wprintf '[+] Cleaning Full Environment files, please wait...'
  sed -i 's/Storage=volatile/#Storage=auto/' ${CHROOT}/etc/systemd/journald.conf
  rm -rf "$CHROOT/etc/udev/rules.d/81-dhcpcd.rules"
  rm -rf "$CHROOT/etc/systemd/system/"{choose-mirror.service,pacman-init.service,etc-pacman.d-gnupg.mount,getty@tty1.service.d}
  rm -rf "$CHROOT/etc/resolv.conf"
  rm -rf "$CHROOT/etc/systemd/scripts/choose-mirror"
  rm -rf "$CHROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf"
  rm -rf "$CHROOT/root/"{.automated_script.sh,.zlogin}
  rm -rf "$CHROOT/etc/mkinitcpio-archiso.conf"
  rm -rf "$CHROOT/etc/initcpio"
  #rm -rf ${CHROOT}/etc/{group*,passwd*,shadow*,gshadow*}
  wprintf "done\n"

  return $SUCCESS
}


# perform sync
sync_disk()
{
  title 'Game Over'

  wprintf '[+] Syncing disk'
  printf "\n\n"

  sync

  return $SUCCESS
}


# setup cynux related stuff
setup_cynux()
{
  update_etc
  sleep_clear 1

  enable_iwd_networkd
  sleep_clear 1

  ask_mirror
  sleep_clear 1
  add_resolv
  install_base_packages
  sleep_clear 1


    setup_display_manager
    sleep_clear 1    
    gnome_setup
    sleep_clear 1


  ask_vbox_setup
  sleep_clear 1

  if [ $VBOX_SETUP -eq $TRUE ]
  then
    setup_vbox_utils
    sleep_clear 1
  fi

  ask_vmware_setup
  sleep_clear 1

  if [ $VMWARE_SETUP -eq $TRUE ]
  then
    setup_vmware_utils
    sleep_clear 1
  fi

  sleep_clear 1

  enable_pacman_multilib 'chroot'
  sleep_clear 1

  enable_pacman_color 'chroot'
  sleep_clear 1

  
  if [ -n "$NORMAL_USER" ]
  then
    update_user_groups
    sleep_clear 1
  fi

  return $SUCCESS
}

# controller and program flow
main()
{
  # do some ENV checks
  sleep_clear 0
  check_uid
  check_env
  check_boot_mode


  # output mode
  ask_output_mode
  sleep_clear 0

  # locale
  ask_locale
  set_locale
  sleep_clear 0

  # keymap
  ask_keymap
  set_keymap
  sleep_clear 0

  # network
  ask_hostname
  sleep_clear 0
  get_net_ifs
  ask_net_if
  sleep_clear 1
  sleep_clear 0
  net_conf_auto
  sleep_clear 1

    check_inet_conn
    sleep_clear 1

    # self updater
    sleep_clear 1

    # pacman
    #ask_mirror_arch
    sleep_clear 1
    update_pacman

  # hard drive
  get_hd_devs
  ask_hd_dev
  sleep_clear 1
  umount_filesystems 'harddrive'
  sleep_clear 1
  ask_cfdisk
  sleep_clear 3
  get_partition_label
  ask_partitions
  print_partitions
  ask_formatting
  clear
  make_partitions
  clear
  mount_filesystems
  sleep_clear 1

  # arch linux
  add_resolv
  pacman_keyring
  sleep_clear 1 
  setup_base_system
  sleep_clear 1
  setup_time
  sleep_clear 1
  add_resolv
  setup_cynux
  sleep_clear 1

  # epilog
  umount_filesystems
  sleep_clear 1
  sync_disk
  sleep_clear 1

  return $SUCCESS
}


# we start here
main "$@"


