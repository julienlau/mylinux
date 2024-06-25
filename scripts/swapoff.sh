#!/bin/bash

unalias testsudo 2>/dev/null
testsudo() {
    echo 'this script needs root perm'
    timeout -s 9 1 sudo echo 'sudo OK'
    if [[ $? -ne 0 ]]; then echo 'ERROR'; exit 9; fi
}

dryrun=0
mode=apply

for i in "$@"; do
    case $i in
        --rollback)
            mode="rollback"
            shift # past argument=value
            ;;
        --dryrun)
            dryrun=1
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo 'run using :'
            echo "sudo $0"' --dryrun'
            echo "sudo $0"' > swap-$(uname -n)-$(date '+%y%m%d')_$(date '+%H%M%S').log 2>&1'
            echo 'Rollback using :'
            echo "sudo $0"' --rollback'
            exit 1
            ;;
        *)
            ;;
    esac
done

set -e
testsudo

date

echo "mode=$mode"
echo "dryrun=$dryrun"
if [[ $dryrun -eq 0 ]]; then
    sleep 2
fi

free -m
if [[ "$mode" == "apply" ]]; then
    echo "swapoff -a"
    if [[ $dryrun -eq 0 ]]; then
        swapoff -a
    fi
else
    echo "swapon -a"
    if [[ $dryrun -eq 0 ]]; then
        swapon -a
    fi
fi
free -m

date
