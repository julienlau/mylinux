#!/bin/bash

# run using : sudo ./minioDiscover.sh > minioDiscover-$HOSTNAME-$(date '+%y%m%d')_$(date '+%H%M%S').log 2>&1
# prereq : sudo yum install -y nmon iostat hwinfo hdparm

minio=local
mc_user=minio-client
#set -e
shopt -s expand_aliases

for i in "$@"; do
    case $i in
        -a=*|--alias=*)
            minio="${a#*=}"
            shift # past argument=value
            ;;
        -u=*|--user=*)
            mc_user="${i#*=}"
            shift # past argument=value
            ;;
        -*|--*)
            echo "Unknown option $i"
            exit 1
            ;;
        *)
            ;;
    esac
done

date

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
free -k
lsmem
echo "===== Disk ====="
lsblk -o NAME,KNAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT
lshw -class disk
smartctl -a /dev/nvme6n1p1
hdparm -i /dev/nvme6n1p1
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

echo "===== sudo -u ${mc_user} mc admin info $minio ====="
sudo -u ${mc_user} mc admin info $minio
echo "===== sudo -u ${mc_user} mc admin config export $minio ====="
sudo -u ${mc_user} mc admin config export $minio
echo "===== sudo -u ${mc_user} mc admin scanner info $minio --interval 10 ====="
sudo -u ${mc_user} mc admin scanner info $minio --interval 10  -q -n 1 --no-color 
echo "===== sudo -u ${mc_user} mc admin info --json $minio ====="
sudo -u ${mc_user} mc admin info --json $minio
