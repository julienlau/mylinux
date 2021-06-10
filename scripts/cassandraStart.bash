#!/bin/bash
unalias exporte 2>/dev/null
exporte()
{
    key=`echo $1 | awk -F '=' '{print $1}'`
    val=`echo $1 | awk -F '=' '{print $2}' | sed 's/^://'`
    valstart=$(echo $val | awk -F ':' '{print $1}')
    valend=$(echo $val | awk -F ':' '{print $NF}')
    if [[ -e $val || ( -e $valstart && ( -z $valend || -e $valend )) ]] ; then
        if [[ -z $key ]] ; then
            export $key=$val
        elif [[ -z $(echo $key | grep -- $val) ]] ; then
            export $key=$val
        fi
    fi
}

i=2
mode=env

if [[ $# -eq 2 ]]; then
    i=$1
    mode=$2
elif [[ $# -eq 1 ]]; then
    i=$1
else
    echo "ERROR ! give at least one input :"
    echo "1/ Index of node/conf. possible values = 2, 3"
    echo "2/ Mode. possible values = start, env"
    exit 9
fi

#export JVM_OPTS="-Xmx3G -Xms500M -XX:+UseConcMarkSweepGC -XX:ParallelCMSThreads=1 -XX:+CMSIncrementalMode -XX:+CMSIncrementalPacing -XX:CMSIncrementalDutyCycleMin=0 -XX:CMSIncrementalDutyCycle=10 -Dcom.sun.management.jmxremote.port=808$i -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"

echo "cassandra node #$i"
echo "mode = $mode"
echo "sudo ifconfig lo:$i 127.0.0.$i"

# in order to avoid problems with python 2.7.11+
export CQLSH_NO_BUNDLED=TRUE

if [[ -z $JAVA_HOME ]]; then
    exporte JAVA_HOME=/usr/java/latest
fi

if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

if [[ $i -eq 2 ]] ; then
    exporte CASSANDRA_HOME=/home/cassandra/datastax-ddc-3.6.0
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    exporte CASSANDRA_CONF=$CASSANDRA_HOME/conf
    \cd $CASSANDRA_HOME/conf
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    . cassandra-env.sh
    PATH=$CASSANDRA_HOME/bin/:$PATH
    \cd -
    "${JAVA:-java}" -version 2>&1
    if [[ "$mode" = "start" ]]; then
        $CASSANDRA_HOME/bin/cassandra -f 
    fi
elif [[ $i -eq 3 ]] ; then
    exporte mydse=/home/cassandra/dse5.0
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    exporte CASSANDRA_HOME=$mydse/resources/cassandra
    exporte CASSANDRA_CONF=$CASSANDRA_HOME/conf
    \cd $CASSANDRA_HOME/conf
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    . cassandra-env.sh
    PATH=$mydse/bin:$PATH
    \cd -
    "${JAVA:-java}" -version 2>&1
    if [[ "$mode" = "start" ]]; then
        $mydse/bin/dse cassandra -f
    fi
fi
echo "done #$i"
