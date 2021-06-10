#!/bin/bash
. /etc/profile
. ~/.bashrc

unalias exporte 2>/dev/null
# avoid to export keys (like PATH or LD_LIBRARYPATH) to value pointing to non existing path or including duplicates
exporte()
{
    # usage: 
    # exporte titi=/usr/bin:/opt/bin ; echo $titi ;  exporte titi=$titi:~/bin ; echo $titi;  exporte titi=$titi:/trou/duc 
    key=`echo $1 | awk -F '=' '{print $1}'`
    vals=$(echo $1 | awk -F '=' '{print $2}')
    valArr=($(echo $vals | sed 's/^://' | sed 's/:/ /g' ))
    unset valstrtmp
    for val in ${valArr[@]}; do 
        if [[ -e $val || ! -z $(ls $val 2>/dev/null) ]] ; then                   #if path exists
            if [[ -z $valstrtmp ]] ; then             #key is initialized if void
                valstrtmp=$val
            elif [[ -z $(echo $valstrtmp | grep -e "^$val:" -e ":$val:" -e ":$val$") ]] ; then  #else it is incremented
                valstrtmp=$valstrtmp:$val
            fi
        # else
        #     echo "Warning ! path $val does not exist and was ignored for key $key by function exporte"
        fi
    done
    export $key=$valstrtmp
    # if [[ -z $valstrtmp ]]; then
    #     echo "Warning ! key $key was unset by function exporte"
    # fi
}

mode=undefined
kafka=off
hbase=off
cassandra=off
hiveserver2=off
flink=off
help=off

for arg in "$@"
do
    case $arg in
        "--env" )
           mode=env;;
        "--start" )
           mode=start;;
        "--stop" )
           mode=stop;;
        "--mkdir" )
           mode=mkdir;;
        "--withkafka" )
           kafka=on;;
        "--withhbase" )
           hbase=on;;
        "--withflink" )
           flink=on;;
        "--withcassandra" )
           withjavatools=on;;
        "--withhive" )
           hiveserver2=on;;
        "--help" )
           help=on;;
   esac
done

echo "Usage:"
echo "./startBigdata.sh --start"
echo "./startBigdata.sh --start --withhbase --withcassandra --withhive"
echo "./startBigdata.sh --stop  --withhbase --withcassandra --withhive"

echo "Inputs:"
echo "mode=$mode"
echo "hbase=$hbase"
echo "flink=$flink"
echo "cassandra=$cassandra"
echo "hiveserver2=$hiveserver2"
if [[ "$help" = "on" ]]; then
    exit 0
fi

export scalaversion=`scala -version 2>&1 | awk -F 'version' '{print $2}' | awk  '{print $1}'`
export scalaver=`echo $scalaversion | awk -F '.' '{print $1"."$2}'`

# from hdp_manual_install_rpm_helper_files-2.5.0.0.1245/scripts/usersAndGroups.sh
theusr=jlu
export HDFS_USER=${theusr}
export YARN_USER=${theusr}
export MAPRED_USER=${theusr}
export PIG_USER=${theusr}
export HIVE_USER=${theusr}
export WEBHCAT_USER=${theusr}
export HBASE_USER=${theusr}
export ZOOKEEPER_USER=${theusr}
export OOZIE_USER=${theusr}
export HADOOP_GROUP=users

# # from hdp_manual_install_rpm_helper_files-2.5.0.0.1245/scripts/directories.sh
# export ZOOKEEPER_DATA_DIR="/home/$ZOOKEEPER_USER/hdp/hadoop/zookeeper/data"
# export ZOOKEEPER_CONF_DIR="/etc/zookeeper/conf"
# export ZOOKEEPER_LOG_DIR="/var/log/zookeeper"
# export ZOOKEEPER_PID_DIR="/var/run/zookeeper"
# export ZOOCFGDIR=$ZOOKEEPER_CONF_DIR
# export ZOOCFG=zoo.cfg

# export DFS_NAME_DIR="/home/$HDFS_USER/hdp/hadoop/hdfs/nn"
# export DFS_DATA_DIR="/home/$HDFS_USER/hdp/hadoop/hdfs/dn"
# export FS_CHECKPOINT_DIR="/home/$HDFS_USER/hdp/hadoop/hdfs/snn"
# export HDFS_LOG_DIR="/var/log/hadoop/hdfs"
# export HDFS_PID_DIR="/var/run/hadoop/hdfs"
# export HADOOP_CONF_DIR="/etc/hadoop/conf"
# export YARN_LOCAL_DIR="/home/$YARN_USER/hdp/hadoop/yarn/local"
# export YARN_LOG_DIR="/var/log/hadoop/yarn" 
# export YARN_LOCAL_LOG_DIR="/home/$YARN_USER/hdp/hadoop/yarn/logs"
# export YARN_PID_DIR="/var/run/hadoop/yarn"
# export MAPRED_LOG_DIR="/var/log/hadoop/mapred"
# export MAPRED_PID_DIR="/var/run/hadoop/mapred"
# export HIVE_CONF_DIR="/etc/hive/conf"
# export HIVE_LOG_DIR="/var/log/hive"
# export HIVE_PID_DIR="/var/run/hive"
# export WEBHCAT_CONF_DIR="/etc/hcatalog/conf/webhcat"
# export WEBHCAT_LOG_DIR="var/log/webhcat"
# export WEBHCAT_PID_DIR="/var/run/webhcat"
# export HBASE_CONF_DIR="/etc/hbase/conf"
# export HBASE_LOG_DIR="/var/log/hbase"
# export HBASE_PID_DIR="/var/run/hbase"
# export PIG_CONF_DIR="/etc/pig/conf"
# export PIG_LOG_DIR="/var/log/pig"
# export PIG_PID_DIR="/var/run/pig"
# export OOZIE_CONF_DIR="/etc/oozie/conf"
# export OOZIE_DATA="/var/db/oozie"
# export OOZIE_LOG_DIR="/var/log/oozie"
# export OOZIE_PID_DIR="/var/run/oozie"
# export OOZIE_TMP_DIR="/var/tmp/oozie"
# export SQOOP_CONF_DIR="/etc/sqoop/conf"

# for ambari commons
exporte PYTHONPATH=$PYTHONPATH:/usr/lib/python2.6/site-packages

#exporte CASSANDRA_HOME=/opt/dse5.0.3
#exporte DSE_HOME=$CASSANDRA_HOME
#exporte CASSANDRA_CONF=$CASSANDRA_HOME/resources/cassandra/conf
exporte CASSANDRA_HOME=/opt/apache-cassandra-3.9
exporte CASSANDRA_CONF=$CASSANDRA_HOME/conf
exporte DRILL_HOME=/opt/apache-drill-1.8.0

. /opt/hadoop/etc/hadoop/hadoop-env.sh
# exporte HADOOP_PREFIX=/opt/hadoop
# exporte HADOOP_HOME=/opt/hadoop
# if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
# exporte HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
# exporte HADOOP_LIBEXEC_DIR=${HADOOP_HOME}/libexec
# #exporte HADOOP_COMMON_DIR=share/hadoop/common
# #exporte HADOOP_COMMON_LIB_JARS_DIR=lib
# #exporte HADOOP_COMMON_LIB_NATIVE_DIR=native
# #export HADOOP_OPTS="-Djava.library.path=${HADOOP_HOME}/lib"
# exporte HDFS_DIR=${HADOOP_HOME}/share/hadoop/hdfs
# exporte HDFS_LIB_JARS_DIR=${HADOOP_HOME}/share/hadoop/hdfs/lib
# exporte MAPRED_DIR=${HADOOP_HOME}/share/hadoop/mapreduce
# exporte MAPRED_LIB_JARS_DIR=${HADOOP_HOME}/share/hadoop/mapreduce/lib
exporte ZOOKEEPER_HOME=/opt/zookeeper
exporte ZOOBINDIR=$ZOOKEEPER_HOME/bin
exporte FLUME_HOME=/opt/apache-flume-1.6.0-bin
exporte HIVE_HOME=/opt/apache-hive-2.0.1-bin
exporte PIG_HOME=/opt/pig-0.15.0
exporte SPARK_HOME=/opt/spark
export SPARK_LOCAL_IP=127.0.0.1
exporte STORM_HOME=/opt/apache-storm-1.0.2
exporte KAFKA_HOME=/opt/kafka_$scalaver-0.10.1.0
exporte HBASE_HOME=/opt/hbase-1.4.2
exporte FLINK_HOME=/opt/flink-1.4.2
export kafka_log_dirs=/tmp/kafka-logs

if [[ "$cassandra" = "on" ]]; then
    exporte CASSANDRA_HOME=/opt/dse5.0.3
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    exporte CASSANDRA_CONF=$CASSANDRA_HOME/resources/cassandra/conf
    #exporte CASSANDRA_CONF=$CASSANDRA_HOME/conf
    . $CASSANDRA_CONF/cassandra-env.sh
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    "${JAVA:-java}" -version 2>&1
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
fi

. $HADOOP_CONF_DIR/hadoop-env.sh 
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
echo $CLASSPATH
. ${HADOOP_HOME}/libexec/hadoop-config.sh
echo $CLASSPATH

#exporte PATH=$PATH:$CASSANDRA_HOME/bin
#exporte PATH=$PATH:$DRILL_HOME/bin
exporte PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:$HBASE_HOME/bin:$ZOOKEEPER_HOME/bin:$FLUME_HOME/bin:$HIVE_HOME/bin:$PIG_HOME/bin:$SPARK_HOME/bin:$KAFKA_HOME/bin:$STORM_HOME/bin:$CASSANDRA_HOME/bin:$DRILL_HOME/bin:$FLINK_HOME/bin
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
exporte LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

echo $PATH

echo "==================================================================="
jps
echo "==================================================================="

if [[ "$mode" = "mkdir" ]]; then
    if [[ ! -z $KAFKA_HOME ]] ; then
        mkdir -p /hadoop/logs /home/data/hadoop/hdfs/namesecondary /home/data/hadoop/hdfs/namenode /home/data/hadoop/hdfs/data /home/data/hadoop/hdfs/journalnode /home/data/zookeeper /var/run/hadoop/yarn /var/run/zookeeper /var/log/zookeeper /var/log/hadoop/yarn /var/run/hbase /var/log/hbase /tp/zookeeper $kafka_log_dirs $KAFKA_HOME/logs
        chown -R ${HDFS_USER}:${HADOOP_GROUP} /home/data/hadoop/hdfs/namesecondary /home/data/hadoop/hdfs/namenode /home/data/hadoop/hdfs/data /home/data/hadoop/hdfs/journalnode /home/data/zookeeper /var/run/hadoop/yarn /var/run/zookeeper /var/log/zookeeper /var/log/hadoop/yarn /var/run/hbase /var/log/hbase /tmp/zookeeper $kafka_log_dirs $KAFKA_HOME/logs
        chmod -R go+rwX /home/data/hadoop/hdfs/namesecondary /home/data/hadoop/hdfs/namenode /home/data/hadoop/hdfs/data /home/data/hadoop/hdfs/journalnode /home/data/zookeeper /var/run/hadoop/yarn /var/run/zookeeper /var/log/zookeeper /var/log/hadoop/yarn /var/run/hbase /var/log/hbase /tmp/zookeeper $kafka_log_dirs $KAFKA_HOME/logs
        chmod -R o+rX /home/data/hadoop/hdfs/namesecondary /home/data/hadoop/hdfs/namenode /home/data/hadoop/hdfs/data /home/data/hadoop/hdfs/journalnode /home/data/zookeeper /var/run/hadoop/yarn /var/run/zookeeper /var/log/zookeeper /var/log/hadoop/yarn /var/run/hbase /var/log/hbase /tmp/zookeeper $kafka_log_dirs $KAFKA_HOME/logs
    fi
elif [[ "$mode" = "start" ]]; then
    echo "==================================================================="
    echo start-dfs.sh
    start-dfs.sh
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    echo "running 'hadoop namenode -format' may be needed"
    echo "==================================================================="
    echo start-yarn.sh
    start-yarn.sh
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    echo "==================================================================="
    if [[ "$hbase" = "on" ]]; then
        echo "start-hbase.sh start"
        start-hbase.sh start
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi
    echo "==================================================================="
    # sudo service nfs stop
    # if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    # sudo service rpcbind stop
    # echo "==================================================================="
    # echo "sudo ${HADOOP_HOME}/bin/hdfs portmap"
    # sudo ${HADOOP_HOME}/bin/hdfs portmap &
    # if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    # sleep 10
    # echo "==================================================================="
    # echo "hdfs nfs3"
    # hdfs nfs3 &
    # if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    # sleep 10
    echo "==================================================================="
    echo "zkServer.sh start $ZOOKEEPER_HOME/conf/zoo.cfg"
    zkServer.sh start $ZOOKEEPER_HOME/conf/zoo.cfg
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    if [[ "$kafka" = "on" ]]; then
        echo "==================================================================="
        echo "kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties"
        kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi
    if [[ "$hiveserver2" = "on" ]]; then
        echo "==================================================================="
        echo "hiveserver2 start"
        hiveserver2 start &
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
        sleep 10
    fi
    if [[ "$cassandra" = "on" ]]; then
        echo "==================================================================="
        echo "$CASSANDRA_HOME/bin/cassandra -f"
        $CASSANDRA_HOME/bin/cassandra -f &
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
        sleep 10
        #> $CASSANDRA_HOME/logs/cassandra.log 2>&1
    fi
    if [[ "$flink" = "on" ]]; then
        echo "$FLINK_HOME/bin/start-local.sh"
        $FLINK_HOME/bin/start-local.sh
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi
elif [[ "$mode" = "stop" ]]; then
    kafka-server-stop.sh
    zkServer.sh stop
    stop-dfs.sh
    stop-yarn.sh
    if [[ "$hbase" = "on" ]]; then
        stop-hbase.sh
    fi
    if [[ "$flink" = "on" ]]; then
        echo "$FLINK_HOME/bin/stop-local.sh"
        $FLINK_HOME/bin/stop-local.sh
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi    #hdfs stop nfs3
    #sudo ${HADOOP_HOME}/bin/hdfs --daemon stop portmap
    #hadoop-daemon.sh stop nfs3
    #sudo ${HADOOP_HOME}/sbin/hadoop-daemon.sh stop portmap
    ps -ef | grep -i -e cassandra -e zookeeper -e kafka -e yarn -e hdfs -e hbase | grep -v grep
    unset listPID
    if [[ "$cassandra" = "on" ]]; then
        listPID=`ps -ef | grep $CASSANDRA_HOME/ | grep -v grep | awk '{print $2}'`
        if [[ ! -z $listPID ]] ; then
            kill -9 $listPID
        fi
    fi
elif [[ "$mode" = "env" ]]; then
    echo "settings env"
else
    echo "error unkown input mode $mode. --start ?"
    exit 270501
fi

ps -ef | grep -i -e cassandra -e zookeeper -e kafka -e yarn -e hdfs -e hbase
echo "==================================================================="
jps
echo "==================================================================="

#sudo rpcinfo -p 127.0.0.1
#sudo showmount -e 127.0.0.1

echo "Done"
