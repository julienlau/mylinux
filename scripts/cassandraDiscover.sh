#!/bin/bash
set -e

if [[ $# -gt 0 ]]; then
    listKs=$1
fi

cassandra_dir=/opt/cassandra
nt="nodetool"

ps -ef | grep java |grep cassandra

if [[ -e ${cassandra_dir}/conf/cassandra.yaml ]]; then
    grep -v -e "^#" -e "^$" -e "\s#" ${cassandra_dir}/conf/cassandra.yaml
fi
if [[ -e ${cassandra_dir}/conf/cassandra-env.sh ]]; then
    grep -v -e "^#" -e "^$" -e "\s#" ${cassandra_dir}/conf/cassandra-env.sh
fi

date

echo "===== System ====="
hostname; uname -a; uptime; echo 'Boot time :'; date -d @$(vmstat --stats | awk '/boot time/ {print $1}'); systemctl list-units
echo "===== Disk ====="
lsblk -o NAME,KNAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT
df -h
echo "===== Clock ====="
timedatectl | grep synchronized;
# ntpstat
systemctl status ntp*.service
echo "===== VERSION ====="
${nt} version
echo "===== INFO ====="
${nt} info
echo "===== STATUS ====="
${nt} status
printf "statusbackup "; ${nt} statusbackup
printf "statusbinary "; ${nt} statusbinary
printf "statusgossip "; ${nt} statusgossip
printf "statushandoff "; ${nt} statushandoff
printf "statusthrift "; ${nt} statusthrift
echo "===== describecluster ====="
${nt} describecluster
echo "===== ring ====="
${nt} ring
echo "===== SCHEMA ====="
cqlsh -e "DESC tables; DESC schema;"

echo "===== compactionhistory ====="
${nt} compactionhistory
echo "===== compactionstats ====="
${nt} compactionstats
echo "===== listsnapshots ====="
${nt} listsnapshots
echo "\n===== gcstats ====="
${nt} gcstats
echo "===== netstats ====="
${nt} netstats
echo "===== proxyhistograms ====="
${nt} proxyhistograms
echo "===== tpstats ====="
${nt} tpstats
echo "===== tablestats ====="
${nt} tablestats

if [[ -z ${listKs} ]]; then
    listKs=`cqlsh -e "DESC keyspaces;" | grep -v -e '^[[:space:]]*$' | sed "s/ /\n/g" | grep -v ^system`
fi

for ks in $listKs; do
    listTable=`cqlsh -e "USE ${ks}; DESC tables;" | grep -v -e '^[[:space:]]*$'`
    for table in $listTable ; do
        echo "===== tablehistograms ${ks} $table ====="
        ${nt} tablehistograms ${ks} $table
        # echo "===== toppartitions ${ks} $table ====="
        # ${nt} toppartitions ${ks} $table 1000
    done
done
