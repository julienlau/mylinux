#!/bin/bash

# Discover linux host
# Run this script with root permissions

date

echo '-----------------------------'
echo HOSTNAME=$HOSTNAME
uname -a
cat /etc/os-release
echo '-----------------------------'
set +x

echo '-----------------------------'
lsmod
echo '-----------------------------'
lshw
echo '-----------------------------'
hwinfo --all
echo '-----------------------------'
lsblk -o name,label,partlabel,size,uuid,mountpoint
echo "===== RA : Read Ahead ====="
blockdev --report


for dev in `lshw -c DISK | grep -e "logical name:" -e "configuration:" | grep -B 1 "configuration:" | grep 'logical name:' | awk '{print $NF}' | grep "^/dev"`; do
    echo '-----------------------------'
    smartctl -a ${dev}
    echo '-----------------------------'
    hdparm -i ${dev}
done

echo "===== MEM ====="
free -k
lsmem
echo "===== Swap ====="
cat /proc/swaps

echo '-----------------------------'
pvdisplay -m
echo '-----------------------------'
lvs -v --segments -o +devices
echo '-----------------------------'
nvidia-smi
echo '-----------------------------'

date
