#!/bin/bash

errchk=0
force=1

nDiskBase=2

fdisk -l > /tmp/fdisk.log
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

if [[ ! -f /etc/fstabcopy ]]; then
    cp /etc/fstab /etc/fstabcopy
fi

nDiskTot=`grep -c "Disk /dev/sd" /tmp/fdisk.log`
nDisk=$(($nDiskTot-$nDiskBase))
if [[ $nDisk -ne 4 ]] ; then echo "WARNING ! NOTHING TO DO nbdisk should be 4 " ; exit 0 ; fi

listDisk=`grep "Disk /dev/sd" /tmp/fdisk.log | tail -$nDisk | tr -d ':' | tr -d ','`
declare -a arrLetter=('c' 'd' 'e' 'f')
declare -a arrDev=('sdc' 'sdd' 'sde' 'sdf')
declare -a arrGb=(128 128 128 128)
arrGb[0]=$(echo $listDisk | awk -F "Disk /dev/sd" '{print $2}' | awk -F "GiB" '{print $1}' | awk  '{print $2}')
arrGb[1]=$(echo $listDisk | awk -F "Disk /dev/sd" '{print $3}' | awk -F "GiB" '{print $1}' | awk  '{print $2}')
arrGb[2]=$(echo $listDisk | awk -F "Disk /dev/sd" '{print $4}' | awk -F "GiB" '{print $1}' | awk  '{print $2}')
arrGb[3]=$(echo $listDisk | awk -F "Disk /dev/sd" '{print $5}' | awk -F "GiB" '{print $1}' | awk  '{print $2}')
echo "SIZE of disks = ${arrGb[@]} "

i=0
while [[ $i -lt $nDisk ]]; do
    mountpoint=/dcos/volume$i
    mkdir -p $mountpoint
    dev=${arrDev[$i]}
    partition=$dev\1
    gib=${arrGb[$i]}
    mib=$((gib*1024))
    if [[ $force -eq 1 || ! -f /var/lib/$dev-gpt ]] ; then 
        echo "TREATING $dev $partition $mountpoint"

        parted -s /dev/$dev mklabel gpt
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? parted" ; exit 1 ; fi

        touch /var/lib/$dev-gpt
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? touch" ; exit 1 ; fi

        echo "n
p
1


w
"|fdisk /dev/$dev
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? fdisk" ; exit 1 ; fi

        mkfs.ext4 -F /dev/$dev
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? mkfs" ; exit 1 ; fi

        thePart=/dev/$dev'1'
        #echo "$thePart      $mountpoint        ext4        defaults,nofail          0    2" >> /etc/fstab
        theUUID=`blkid /dev/$dev | awk '{print $2}'  | sed 's/PARTUUID=//g' | tr -d '"'`
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? blkid" ; exit 1 ; fi

        echo "$theUUID      $mountpoint        ext4        defaults,nofail          0    2" >> /etc/fstab
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? fstab" ; exit 1 ; fi

        udevadm trigger
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? udevadm" ; exit 1 ; fi

        mount $mountpoint
        if [[ $? -ne 0 && $errchk -ne 0 ]] ; then echo "ERROR ! shell $? mount" ; exit 1 ; fi
    fi

    i=$(($i+1))
done

echo "Done"

# UUID=5bd866fd-daf0-4635-92fa-6344d28ae702
# UUID=1bcee825-9d9d-4c1f-b240-f4399fe0a95f
# UUID=062d9d5e-daf5-4c37-8ddc-da22b0a97c93
# UUID=ab4af278-b6f9-49a1-96fc-761b2adc30d4
