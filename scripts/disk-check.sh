#!/bin/bash
# check disk status based on smartctl logs
# If you are unsure about the health status, consider 
# isolating the disk and running a smart test with : smartctl -t long /dev/XXX

disk=all
ignore=0
shopt -s expand_aliases

for i in "$@"; do
    case $i in
        -d=*|--disk=*)
            disk="${d#*=}"
            shift # past argument=value
            ;;
        -i|--ignore)
            ignore=1
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo 'run using :'
            echo "sudo $0"''
            echo "sudo $0 -d /dev/sda --ignore"''
            exit 1
            ;;
        *)
            ;;
    esac
done

date

errglobal=0
errlist=""

list=$disk
if [[ "$disk" == "all" ]]; then
    list=$(lsblk -d -o TYPE,NAME,UUID,LABEL,MOUNTPOINT | grep -v -e '^loop' -e '^TYPE' | awk '{print $2}')
fi


for dev in $list; do
    err=0

    lines=$(smartctl -a /dev/$dev)
    if [[ $? -ne 0 ]]; then
        if [[ $(echo "$lines" | tail -1) == "Device does not support Self Test logging" ]]; then
            # if there is a hardware RAID, this is the right command
            echo "switching to smartctl command with option -d cciss,0"
            lines=$(smartctl -a -d cciss,0 /dev/$dev)
            if [[ $? -ne 0 ]]; then echo "ERROR smartctl -d cciss,0 $dev" ; err=$(($err+1)) ; fi
        else
            echo "ERROR smartctl $dev" ; err=$(($err+1))
        fi
    fi

    disktype=other
    if [[ $(echo $dev | grep -c '^nvme') -ne 0 ]]; then
        disktype=nvme
    fi

    if [[ "$disktype" == "nvme" ]]; then
        res=$(echo "$lines" | grep 'SMART overall-health self-assessment test result: PASSED')
        if [[ $? -ne 0 ]]; then echo "ERROR health $dev" ; err=$(($err+1)) ;fi

        res=$(echo "$lines" | grep 'Critical Warning:' | awk '{print $NF}')
        if [[ "$res" != "0x00" || $? -ne 0 ]]; then echo "ERROR Warning $dev" ; err=$(($err+1)) ;fi
    else
        res=$(echo "$lines" | grep 'Health Status: OK')
        if [[ $? -ne 0 ]]; then echo "ERROR health $dev" ; err=$(($err+1)) ;fi

        res=$(echo "$lines" | grep 'Elements in grown defect list' | awk '{print $NF}')
        if [[ $res -gt 0 || $? -ne 0 ]]; then echo "ERROR defect $dev" ; err=$(($err+1)) ;fi

        res=$(echo "$lines" | grep -A 5 'Error counter log' | grep -e '^read' | awk '{print $NF}')
        if [[ $res -gt 0 || $? -ne 0 ]]; then echo "ERROR read $dev" ; err=$(($err+1)) ;fi

        res=$(echo "$lines" | grep -A 5 'Error counter log' | grep -e '^write' | awk '{print $NF}')
        if [[ $res -gt 0 || $? -ne 0 ]]; then echo "ERROR write $dev" ; err=$(($err+1)) ;fi
    fi
    if [[ $err -eq 0 ]]; then
        echo "  check on dev $dev OK"
    else
        errlist="$errlist $dev"
        echo "$lines" | grep -e Health -e 'Errors Corrected by' -e 'ECC' -e '^read' -e '^write' -e 'Critical Warning' -e 'overall-health' -e 'grown defect list'
    fi
    errglobal=$(($errglobal+$err))
done

if [[ $errglobal -gt 0 ]]; then
    lsblk -d -o TYPE,NAME,UUID,LABEL,MOUNTPOINT
    echo "$(hostname) list of devices with error: $errlist"
    echo "ERROR ! smart error detected $errglobal"
    if [[ ! $ignore ]]; then
        exit 27
    fi
fi
