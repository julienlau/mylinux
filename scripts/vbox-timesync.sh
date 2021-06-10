#!/bin/bash
set -e

vboxpath=~/VirtualBoxVMs
cd ${vboxpath}

SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
vmnames=(`VBoxManage list vms | awk -F ' {' '{print $1}'`)
vmids=(`VBoxManage list vms | awk '{print $NF}'`)
IFS=$SAVEIFS


echo "Warning NTP/chrony should be disabled on the guest OS !!!"
i=0
while [[ $i -lt ${#vmids[@]} ]]; do 
    vmname=${vmids[$i]}
    i=$(($i+1))
    echo ${vmnames[$i]} ${vmids[$i]}
    # Specifies the interval at which to synchronize the time with the host. The default is 10000 ms (10 seconds).
    VBoxManage guestproperty set "${vmname}" "/VirtualBox/GuestAdd/VBoxService/--timesync-interval" 86400000
    # The minimum absolute drift value measured in milliseconds to make adjustments for. The default is 1000 ms on OS/2 and 100 ms elsewhere. 
    VBoxManage guestproperty set "${vmname}" "/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust" 100
    # The absolute drift threshold, given as milliseconds where to start setting the time instead of trying to smoothly adjust it. The default is 20 minutes.
    VBoxManage guestproperty set "${vmname}" "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold" 1200000
    # The factor to multiply the time query latency with to calculate the dynamic minimum adjust time. The default is 8 times
    VBoxManage guestproperty set "${vmname}" "/VirtualBox/GuestAdd/VBoxService/--timesync-latency-factor" 8
    # Set the time after the VM was restored from a saved state when passing 1 as parameter. This is the default. Disable by passing 0. In the latter case, the time will be adjusted smoothly, which can take a long time.
    VBoxManage guestproperty set "${vmname}" "/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore" 1
done
