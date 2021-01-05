#!/bin/bash

SUCCESS=0
FAILURE=1

function get_disks()
{
 echo "Disk Available"
diskout=$(fdisk -l | grep Disk |grep /dev |awk '{print $2}'|sed 's\:\\g')
echo -e "${RED}$diskout${reset}"
echo -n "Choose a Disk: "
read disk

for output in $diskout
do
        if [ $disk = $output  ]
        then
                #echo "Valid Disk"
                confirmdisk=$disk
                break
        else
                continue
        fi
done

echo $confirmdisk
if [ -z $confirmdisk  ]
then
        echo "Invalid Disk"
        diskask
else
        echo "Valid Disk"
fi
}

get_disks

function autopart()
{
	echo "Parting the boot disk"
	echo "Making GPT Partition(Default)..."
	/sbin/parted $confirmdisk mklabel gpt --script
	echo "Making Boot partition of 500MB..."
        /sbin/parted $confirmdisk mkpart primary fat16 0% 500MB --script	
	echo "Making Swap Partition of 2GB..."
	/sbin/parted $confirmdisk mkpart primary linux-swap 500MB 2GB --script
	echo "Making Root Partition of Remaing space..."
	/sbin/parted $confirmdisk mkpart primary ext4 2GB 100% --script

	parted_disk=$(fdisk -l |grep $confirmdisk |awk '{print $1}' |grep -v Disk)
	echo "Disk Formed..."
	echo $parted_disk
	Disk_Per_line=$(echo $parted_disk |sed ':a;N;$!ba;s/\n/ /g')
	BOOT_PART=$(echo $Disk_Per_line |awk '{print $1}')
	SWAP_PART=$(echo $Disk_Per_line |awk '{print $2}')
	ROOT_PART=$(echo $Disk_Per_line |awk '{print $3}')
	echo "Formatiting the Partition..."
	mkfs.ext4 $ROOT_PART
	mkswap $SWAP_PART
	echo "Turning SwapON..."
	swapon $SWAP_PART

	return $SUCCESS
}
autopart

