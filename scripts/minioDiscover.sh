#!/bin/bash

minioalias=local
mc_user=minio-client
mc="mc"
#set -e
shopt -s expand_aliases

for i in "$@"; do
    case $i in
        -a=*|--alias=*)
            minioalias="${i#*=}"
            shift # past argument=value
            ;;
        -u=*|--user=*)
            mc_user="${i#*=}"
            shift # past argument=value
            ;;
        --sudo)
            sudo=1
            shift
            ;;
        -*|--*)
            echo "Unknown option $i"
            echo 'run using :'
            echo "sudo $0"' > minioDiscover-$(uname -n)-$(date '+%y%m%d')_$(date '+%H%M%S').log 2>&1'
            echo 'prereq : sudo apt install -y nmon hwinfo bpfcc-tools linux-headers-$(uname -r)'
            exit 1
            ;;
        *)
            ;;
    esac
done

date

if [[ "$sudo" == "1" ]]; then
    mc="sudo -u ${mc_user} mc"
    testsudo
fi

echo '-----------------------------'
echo HOSTNAME=$HOSTNAME
uname -a
cat /etc/os-release
echo '-----------------------------'

echo "===== System ====="
hostname; uname -a; uptime; echo 'Boot time :'; date -d @$(vmstat --stats | awk '/boot time/ {print $1}'); systemctl list-units --no-pager
echo "scaling_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"
echo "zone_reclaim_mode=$(cat /proc/sys/vm/zone_reclaim_mode)"
echo "transparent_hugepage_defrag=$(cat /sys/kernel/mm/transparent_hugepage/defrag)"
head /sys/block/*/queue/scheduler
echo "===== CPU ====="
lscpu
echo "===== MEM ====="
free -m
lsmem
echo "===== Disk ====="
cat /etc/fstab
lsblk -o NAME,KNAME,MAJ:MIN,RM,SIZE,RO,TYPE,UUID,LABEL,MOUNTPOINT
lshw -class disk
# TODO : adapt to conf
smartctl -a /dev/sd*
hdparm -i /dev/sd*
hwinfo --disk
pvdisplay -m
lvs --segments -o +devices
df -h
echo "===== RA : Read Ahead ====="
blockdev --report
echo "===== Swap ====="
cat /proc/swaps
echo "===== Clock ====="
timedatectl | grep synchronized;
# ntpstat
systemctl status ntp*.service chrony*.service
chronyc tracking || ntpq -c rl
echo "===== ulimit ====="
ulimit -a
echo "===== Sysctl ====="
sysctl -p
echo "===== fs.file-max ====="
echo "fs.file-max=$(cat /proc/sys/fs/file-max)"
echo "===== sockets summary ====="
ss -s

echo "===== /lib/systemd/system/minio.service ====="
cat /lib/systemd/system/minio.service || echo ""
echo "===== /etc/default/minio ====="
grep -v -i password /etc/default/minio || echo ""
echo "===== ${mc} admin info $minioalias ====="
${mc} admin info $minioalias
echo "===== ${mc} admin config export $minioalias ====="
${mc} admin config export $minioalias
echo "===== ${mc} admin scanner info $minioalias --interval 10 ====="
${mc} admin scanner info $minioalias --interval 10  -q -n 1 --no-color
echo "===== ${mc} admin info --json $minioalias ====="
${mc} admin info --json $minioalias
echo "===== ${mc} ilm tier info $minioalias ====="
${mc} ilm tier info $minioalias
echo "===== ${mc} ilm tier ls $minioalias ====="
${mc} ilm tier ls $minioalias
echo "===== timeout 3 xfsslower-bpfcc 1 ====="
timeout 3 xfsslower-bpfcc 1
