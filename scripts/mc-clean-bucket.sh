#!/bin/bash
# $0 -t=ALIAS/BUCKET/PATH
# The script can be run concurrently on the same host to speed up delete process.
# sudo nohup ./mc-clean-bucket.sh --target=myminio-local/BUCKET/PATH/ &
# Verify the number of directory pending removal : wc -l /tmp/mc-clean-bucket-*

target=""
iamok=0
purge=0

for i in "$@"; do
    case $i in
        --iamok)
            iamok=1
            shift # past argument=value
            ;;
        --purge)
            purge=1
            shift # past argument=value
            ;;
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

# NB : be aware of trailing slash "mc rm -r alias/toto" behaves like "rm -r alias/toto*"
# remove trailing slash
target_no_trailing_slash="${target%%/}"
# enforce trailing slash to avoid issues with prefix mc rm -r without trailing slash
target="${target_no_trailing_slash}/"

echo "Warning the complete recurisve path ${target} will be erased using client hosted on ${HOSTNAME}"
if [[ ${iamok} -eq 1 ]]; then 
    sleep 10
fi

mcls=mc-clean-bucket-$(echo ${target} | sed "s:/:--:g")
echo "status file is /tmp/${mcls}"

iter=0
mcline=1
while [[ $iter -le $(($mcline * 5)) && $mcline -gt 0 ]]; do
    if [[ $(echo ${target_no_trailing_slash} | grep -o "/" | wc -l 2>/dev/null) -lt 2 ]] ; then
        echo "ERROR : if you want to delete a full bucket use mc rb. Please check your target : ${target_no_trailing_slash}"
        exit 9999
    fi
    if [[ ! -e /tmp/${mcls} || ! -z $(find /tmp/ -type f -mmin +2 -name ${mcls} 2>/dev/null) ]] ; then
        mc ls ${target_no_trailing_slash}/ > /tmp/${mcls}
        iter=0
    fi
    mcline=$(wc -l /tmp/${mcls}| awk '{print $1}')
    # echo "iamok=${iamok} iter=$iter mcline=$mcline"
    if [[ ${iamok} -eq 1 ]]; then
        if [[ $mcline -gt 0 ]] ; then
            i=$(( ( RANDOM % $mcline )  + 1 ))
            iter=$(($iter+1))
            objpath=$(sed -n "${i}p" /tmp/${mcls} | awk '{print $NF}')
            echo "mc rm -r --force ${target_no_trailing_slash}/${objpath}"
            mc rm -r --force "${target_no_trailing_slash}/${objpath}"
        else
            mcline=$(wc -l /tmp/${mcls}| awk '{print $1}')
        fi
    else
        # dry run
        echo "number of object-path to delete: ${mcline} as listed in /tmp/${mcls}"
        head /tmp/${mcls}
        echo "..."
        tail /tmp/${mcls}
        echo "If you are OK, then re run the script with flag: --iamok"
        exit 0
    fi
done

# NB : always use trailing slash with "mc rm -r"
echo "mc rm -r --force ${target_no_trailing_slash}/"
mc rm -r --force "${target_no_trailing_slash}/"

if [[ ${purge} -eq 1 ]]; then
    echo "mc rm --purge --force ${target_no_trailing_slash}/"
    mc rm --purge --force "${target_no_trailing_slash}/"
fi

if [[ -e /tmp/${mcls} ]] ; then
    rm -f /tmp/${mcls}
fi

echo "Done $0 $$"
