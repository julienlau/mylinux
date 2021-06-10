#!/bin/bash

date
hostname
uname -r
lspci | grep Ethernet

allnic="eth0 eth1"
if [[ ! -z $(which ip 2>/dev/null) ]]; then
    allnic=`ip route | grep '^[0-9]' | awk '{ print $3}' | sort |uniq`
fi

if [[ ! -z $(which ip 2>/dev/null) ]]; then
    ip -s -s link
else
    ifconfig
fi
#echo "if /proc/sys/net/ipv4/ip_no_pmtu_disc == 0 then packet exceeding MTU size will be dropped and not split"
printf "MTU ip_no_pmtu_disc="; cat /proc/sys/net/ipv4/ip_no_pmtu_disc

netstat -s
for nic in $allnic ; do
    echo "++ ethtool $nic"
    ethtool $nic
    echo "++ ethtool -k $nic"
    ethtool -k $nic
    echo "++ ethtool -S $nic"' | egrep "err|dropped|fail" | grep -v  ": 0$"'
    ethtool -S $nic | egrep "err|dropped|fail" | grep -v  ": 0$"
    echo "++ ifconfig $nic | grep 'dropped'"
    ifconfig $nic | grep 'dropped'

    echo '++ egrep "CPU0|$nic" /proc/interrupts'
    egrep "CPU0|$nic" /proc/interrupts
done

echo '++ cat /proc/net/softnet_stat'
cat /proc/net/softnet_stat

if [[ ! -z $(which dropwatch 2>/dev/null) ]]; then
    echo start > /tmp/in
    echo '++ timeout -s 2 -k 1 30 dropwatch -l kas'
    timeout -s 2 -k 1 30 dropwatch -l kas < /tmp/in
    rm -f /tmp/in
fi

echo "somaxconn = $(sysctl net.core.somaxconn)"
echo "netdev_budget : $(sysctl net.core.netdev_budget)"
echo "netdev_max_backlog : $(sysctl net.core.netdev_max_backlog)"

# netstat : deprecated and use different dico : TIME_WAIT instead of TIME-WAIT
echo "nb tcp conn total      = $(ss -anp |grep tcp |wc -l)"
echo "nb tcp conn TIME_WAIT  = $(ss -ant |grep TIME-WAIT |wc -l)"
echo "nb tcp conn CLOSE_WAIT = $(ss -ant |grep CLOSE-WAIT |wc -l)"
echo "nb tcp conn SYN_REC (somaxconn) = $(ss -ant | grep SYN-REC |wc -l)"

ss -s
