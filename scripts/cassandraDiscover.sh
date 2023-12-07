#!/bin/bash

# run using : sudo ./cassandraDiscover.sh > cassandraDiscover-$HOSTNAME-$(date '+%y%m%d')_$(date '+%H%M%S').log 2>&1
# prereq : sudo yum install -y nmon iostat hwinfo hdparm
# if ENV is undefined we cannot now if it is safe to run toppartitions
# if list keyspace is not defined, all keyspaces are analyzed

#set -e
shopt -s expand_aliases

for i in "$@"; do
    case $i in
        -e=*|--env=*)
            ENV="${i#*=}"
            shift # past argument=value
            ;;
        -k=*|--keyspaces=*)
            listKs="${i#*=}"
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


if [[ -z $ENV ]]; then
    echo "var ENV is not defined"
    exit 1
fi

date

#### TO BE ADAPTED TO THE ENV ###
export cassandra_dir=/opt/apache-cassandra-4.1.3
export cassandra_dir=/product/cassandra/default
#alias mynt='nodetool'
#alias mycqlsh='cqlsh'
alias mynt='sudo -u cassandra ${cassandra_dir}/bin/nodetool'
alias mycqlsh='sudo -u cassandra ${cassandra_dir}/bin/cqlsh'
#alias mynt='ccm node1 nodetool'
#alias mycqlsh='ccm node1 cqlsh -u cassandra -p cassandra'
#################################

echo '-----------------------------'
echo HOSTNAME=$HOSTNAME
uname -a
cat /etc/os-release
echo '-----------------------------'

java -version
ps -ef | grep java |grep cassandra

if [[ -e ${cassandra_dir}/conf/cassandra.yaml ]]; then
    grep -v -e "^#" -e "^$" -e "\s#" ${cassandra_dir}/conf/cassandra.yaml
fi
if [[ -e ${cassandra_dir}/conf/cassandra-env.sh ]]; then
    grep -v -e "^#" -e "^$" -e "\s#" ${cassandra_dir}/conf/cassandra-env.sh
fi

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
echo "===== ulimit ====="
ulimit -a
echo "===== Sysctl ====="
sysctl -p
echo "===== Connection to cassandra (assuming use of standard port 9042) ====="
lsof -i -n -P | grep 9042 | grep ESTABLISHED

echo "===== VERSION ====="
mynt version
echo "===== INFO ====="
mynt info
echo "===== STATUS ====="
mynt status
echo ""
printf "statusbackup "; mynt statusbackup
printf "statusbinary "; mynt statusbinary
printf "statusgossip "; mynt statusgossip
printf "statushandoff "; mynt statushandoff
printf "statusthrift "; mynt statusthrift
echo "===== describecluster ====="
mynt describecluster
echo "===== cqlsh ====="
mycqlsh -e 'SELECT * FROM system.peers;SELECT * FROM system.local;'
mycqlsh -e 'SELECT * FROM system.peer_events;SELECT * FROM system.range_xfers;'
echo "===== ring ====="
mynt ring
echo "===== SCHEMA ====="
mycqlsh -e "DESC tables;DESC schema;SELECT * FROM system_schema.views;DESC KEYSPACE system_traces;DESC KEYSPACE system_auth;DESC KEYSPACE system_distributed;"
echo "===== compactionhistory ====="
mynt compactionhistory
echo "===== compactionstats ====="
mynt compactionstats
echo "===== listsnapshots ====="
mynt listsnapshots
echo "\n===== gcstats ====="
mynt gcstats
echo "===== netstats ====="
mynt netstats
echo "===== proxyhistograms ====="
mynt proxyhistograms
echo "===== tpstats ====="
mynt tpstats
echo "===== tablestats ====="
mynt tablestats
echo "===== tablestats END ====="

if [[ -z ${listKs} ]]; then
    listKs=`mycqlsh -e 'DESC keyspaces;' | grep -v -e '^[[:space:]]*$' | sed 's/ /\n/g' | grep -v ^system`
fi

for ks in $listKs; do
    #echo "Keyspace: ${ks}"
    listTable=`mycqlsh -e "USE ${ks}; DESC tables;" | grep -v -e '^[[:space:]]*$'`
    for table in $listTable ; do
        echo "===== tablehistograms ${ks} $table ====="
        mynt tablehistograms ${ks} $table
        if [[ ! -z $ENV && "$ENV" != "prod" && "$ENV" != "PROD" ]]; then
            echo "===== toppartitions ${ks} $table (20000ms) ====="
            mynt toppartitions ${ks} $table 20000
        fi
    done
done
