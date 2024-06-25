#!/bin/bash

unalias testsudo 2>/dev/null
testsudo() {
    echo 'this script needs root perm'
    timeout -s 9 1 sudo echo 'sudo OK'
    if [[ $? -ne 0 ]]; then echo 'ERROR'; exit 9; fi
}

dryrun=0
dev=/dev/sda
ra=256

for i in "$@"; do
    case $i in
        -r=*|--ra=*)
            ra="${i#*=}"
            shift # past argument=value
            ;;
        -d=*|--dev=*)
            dev="${i#*=}"
            shift # past argument=value
            ;;
        --dryrun)
            dryrun=1
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo "run using :"
            echo "sudo $0 --ra=0 -d=/dev/sd --dryrun"
            echo "sudo $0"' --ra=0 -d=/dev/sd > readahead-$(uname -n)-$(date '+%y%m%d')_$(date '+%H%M%S').log 2>&1'
            echo "Rollback using :"
            echo "sudo $0 --ra=256"
            exit 1
            ;;
        *)
            ;;
    esac
done

set -e
testsudo

date

echo "ra=$ra sectors (usual default is 256. To disable read ahead use 0)"
echo "dev=$dev"
echo "dryrun=$dryrun"
if [[ $dryrun -eq 0 ]]; then
    sleep 2
fi

blockdev --report
#for dev in $(cat /etc/fstab | grep " /data/[0-9]" | awk '{print $1}') ; do
for dev in $(blockdev --report | grep "$dev" | awk '{print $NF}') ; do
    echo "blockdev --setra $ra $dev"
    if [[ $dryrun -eq 0 ]]; then
        blockdev --setra $ra $dev
    fi
done
blockdev --report

date
