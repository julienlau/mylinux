#!/bin/bash
#
# Yury V. Zaytsev <yury@shurup.com> (C) 2011
#
# Modified by Erico Mendonca (erico.mendonca@suse.com) to add the following:
# 
# - SUSE paths
# - progress messags
# - tighter scope (only change the VMs that use the supplied network name)
#
# (dec 2018)
#
# This work is herewith placed in public domain.
#
# Use this script to cleanly restart the default libvirt network after its
# definition have been changed (e.g. added new static MAC+IP mappings) in order
# for the changes to take effect. Restarting the network alone, however, causes
# the guests to lose connectivity with the host until their network interfaces
# are re-attached.
#
# The script re-attaches the interfaces by obtaining the information about them
# from the current libvirt definitions. It has the following dependencies:
#
#   - virsh (obviously)
#   - tail / head / grep / awk / cut
#   - XML::XPath (e.g. perl-XML-XPath package)
#
# Note that it assumes that the guests have exactly 1 NAC each attached to the
# given network! Extensions to account for more (or none) interfaces etc. are,
# of course, most welcome.
#
# ZYV
#

# For static IP assignment :
# $> virsh  dumpxml  MyVmName | grep 'mac address'
# $> virsh  net-list
# $> virsh  net-edit  default
#   <ip address='192.168.122.1' netmask='255.255.255.0'>
#     <dhcp>
#       <range start='192.168.122.2' end='192.168.122.254'/>
#       <host mac='52:54:00:27:77:79' name='ubuntu-20' ip='192.168.122.20'/>
#       <host mac='52:54:00:27:77:21' name='ubuntu-21' ip='192.168.122.21'/>
#       <host mac='52:54:00:27:77:22' name='ubuntu-22' ip='192.168.122.22'/>
#     </dhcp>
#   </ip>
# $> ./kvm-network-restart.sh default

set -e

if [ -z $1 ]; then
	echo "Usage: $0 <network name>"
	exit 1
fi

NETWORK_NAME=$1
NETWORK_HOOK=/etc/libvirt/hooks/qemu

echo "--> restarting network $NETWORK_NAME"
virsh net-define /etc/libvirt/qemu/networks/$NETWORK_NAME.xml
virsh net-destroy $NETWORK_NAME
virsh net-start $NETWORK_NAME
echo "--> network restarted"

MACHINES=$( virsh list | tail -n +3 | head -n -1 | awk '{ print $2; }' )

for m in $MACHINES ; do
    echo "---> processing VM: $m"

    MACHINE_INFO=$( virsh dumpxml "$m" | xpath -e /domain/devices/interface[1] 2> /dev/null )
    MACHINE_MAC=$( echo "$MACHINE_INFO" | grep "mac address" | cut -d '"' -f 2 )
    MACHINE_MOD=$( echo "$MACHINE_INFO" | grep "model type" | cut -d '"' -f 2 )
    MACHINE_NET=$( echo "$MACHINE_INFO" | grep "source network" | cut -d '"' -f 2 )

    if [ "$MACHINE_NET" == "$NETWORK_NAME" ]; then
	echo "--> detaching and attaching interfaces for mac address $MACHINE_MAC ($m)"
	set +e
	virsh detach-interface "$m" network --mac "$MACHINE_MAC" && sleep 3
	virsh attach-interface "$m" network $NETWORK_NAME --mac "$MACHINE_MAC" --model "$MACHINE_MOD"
	set -e

        if [[ -x $NETWORK_HOOK ]]; then
	    echo "--> calling network hook script"
	    $NETWORK_HOOK "$m" stopped && sleep 3
	    $NETWORK_HOOK "$m" start
        fi
    else
	echo "--> machine $m is not attached to network $NETWORK_NAME, skipping"
    fi
    echo "--> done"
done
