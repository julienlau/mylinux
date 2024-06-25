#!/bin/bash

minio=local
mc_user=minio-client
#set -e
shopt -s expand_aliases

for i in "$@"; do
    case $i in
        -a=*|--alias=*)
            minio="${i#*=}"
            shift # past argument=value
            ;;
        -u=*|--user=*)
            mc_user="${i#*=}"
            shift # past argument=value
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
testsudo

echo '-----------------------------'
echo HOSTNAME=$HOSTNAME
uname -a
cat /etc/os-release
echo '-----------------------------'

echo "===== System ====="
hostname; uname -a; uptime; echo 'Boot time :'; date -d @$(vmstat --stats | awk '/boot time/ {print $1}'); systemctl list-units --no-pager
echo "===== CPU ====="
lscpu
echo "===== MEM ====="
free -m
lsmem
echo "===== Disk ====="
cat /etc/fstab
lsblk -o NAME,KNAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT
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
echo "===== sudo -u ${mc_user} mc admin info $minio ====="
sudo -u ${mc_user} mc admin info $minio
echo "===== sudo -u ${mc_user} mc admin config export $minio ====="
sudo -u ${mc_user} mc admin config export $minio
echo "===== sudo -u ${mc_user} mc admin scanner info $minio --interval 10 ====="
sudo -u ${mc_user} mc admin scanner info $minio --interval 10  -q -n 1 --no-color 
echo "===== sudo -u ${mc_user} mc admin info --json $minio ====="
sudo -u ${mc_user} mc admin info --json $minio
echo "===== timeout 3 xfsslower-bpfcc 1 ====="
timeout 3 xfsslower-bpfcc 1
