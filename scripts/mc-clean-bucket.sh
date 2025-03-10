#!/bin/bash
# $0 -t=ALIAS/BUCKET/PATH
# The script can be run concurrently on the same host to speed up delete process.

target=""

for i in "$@"; do
    case $i in
        -t=*|--target=*)
            target="${i#*=}"
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo "target=${target}"
            exit 1
            ;;
        *)
            ;;
    esac
done

if [[ "${target}" == "" ]]; then
    echo "ERROR incorrect input : --target="
    exit 99
fi

echo "Warning the complete recurisve path ${target} will be erased using client hosted ${hostname}"
sleep 10

mcls=mc-clean-bucket-$(echo ${target} | sed "s:/:--:g")

init=1
mcline=0
while [[ $init -eq 1 || $mcline -gt 0 ]]; do
    if [[ ! -e /tmp/${mcls} || ! -z $(find /tmp/ -type f -mmin +5 -name ${mcls} 2>/dev/null) ]] ; then
        mc ls ${target}/ > /tmp/${mcls}
        init=0
    fi
    mcline=$(wc -l /tmp/${mcls}| awk '{print $1}')
    if [[ $mcline -gt 0 ]] ; then
        i=$(( ( RANDOM % $mcline )  + 1 ))
        dir=$(sed -n "${i}p" /tmp/${mcls} | awk '{print $NF}')
        echo "mc rm -r --force $target/$dir"
        mc rm -r --force "$target/$dir"
    else
        mcline=$(wc -l /tmp/${mcls}| awk '{print $1}')
    fi
done

echo "Done $0 $$"
