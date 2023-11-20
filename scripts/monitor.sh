#!/bin/bash

# Takes one optionnal argument : duration of the capture in minutes
# script can be launched through ssh on a fleet of servers
# when record finished copy back all output files : *.nmon *mymonitor* to your local VM and use NMONvisualizer

unalias clearcache 2>/dev/null
clearcache() {
    # Clear Linux PageCache only.
    # needs root perm
    echo "Clear Linux PageCache"
    timeout -s 9 60 sudo -- bash -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
    if [[ $? -ne 0 ]]; then echo 'ERROR during clearcache'; exit 9; fi
}

unalias testsudo 2>/dev/null
testsudo() {
    echo 'this script needs root perm'
    timeout -s 9 1 sudo echo 'sudo OK'
    if [[ $? -ne 0 ]]; then echo 'ERROR'; exit 9; fi
}

durationMinute=20
enableTcpdump=0
enableIostat=0
install=0
path=/tmp
intervalSec=2

for i in "$@"; do
    case $i in
        -p=*|--path=*)
            path="${i#*=}"
            shift # past argument=value
            ;;
        -d=*|--durationMinute=*)
            durationMinute="${i#*=}"
            shift # past argument=value
            ;;
        -s=*|--intervalSec=*)
            intervalSec="${i#*=}"
            shift # past argument=value
            ;;
        -t|--enableTcpdump)
            enableTcpdump=1
            shift # past argument=value
            ;;
        -i|--enableIostat)
            enableIostat=1
            shift # past argument with no value
            ;;
        --install)
            install=1
            shift # past argument with no value
            ;;
        -*|--*)
            echo "Unknown option $i"
            exit 1
            ;;
        *)
            ;;
    esac
done


if [[ $install -eq 1 ]]; then
    testsudo
    # centos
    sudo yum install -y nmon tcpdump sysstat
    if [[ $? -ne 0 ]]; then echo 'ERROR'; exit 9; fi
fi
set -e

cd $path

time=$((60 * $durationMinute))
count=$(($time/$intervalSec))
time=$(($time+10))

echo "nmon -f -r mymonitor -s ${intervalSec} -c ${count}"
nmon -f -r mymonitor -s ${intervalSec} -c ${count}

if [[ $enableIostat -eq 1 ]]; then
    echo "iostat -tNxm ${step} ${count}"
    export S_TIME_FORMAT=ISO
    timeout -s 2 -k 1 ${time} iostat -tNxm ${step} ${count} > $(pwd)/iostat-mymonitor-${HOSTNAME}_$(date '+%y%m%d')_$(date '+%H%M').log &
fi

if [[ $enableTcpdump -eq 1 ]]; then
    echo "tcpdump -i eth0 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)'"
    timeout -s 2 -k 1 ${time} tcpdump -i eth0 -C 1000 -W 9 -s 1024 'tcp port 80 and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)' -w $(pwd)/tcpdump-mymonitor-${HOSTNAME}_$(date '+%y%m%d')_$(date '+%H%M').pcap
fi

ps -f

echo "done"
