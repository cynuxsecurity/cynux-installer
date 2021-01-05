#!/usr/bin/env bash
#==============================================================================#
#									       #
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

  if ! curl -s https://google.com > $VERBOSE
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
  if [ $LUKS = $TRUE ]
  then
    make_luks_partition "$ROOT_PART"
    sleep_clear 1
    open_luks_partition "$ROOT_PART" "$CRYPT_ROOT"
    sleep_clear 1
    title 'Hard Drive Setup > Partition Creation (root crypto)'
    wprintf '[+] Creating encrypted ROOT partition'
    printf "\n\n"
    if [ "$ROOT_FS_TYPE" = 'btrfs' ]
    then
      mkfs.$ROOT_FS_TYPE -f "/dev/mapper/$CRYPT_ROOT" > $VERBOSE 2>&1 ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    else
      mkfs.$ROOT_FS_TYPE -F "/dev/mapper/$CRYPT_ROOT" > $VERBOSE 2>&1 ||
        { err 'Could not create filesystem'; exit $FAILURE; }
    fi
    sleep_clear 1
  else
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
    sleep_clear 1
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

