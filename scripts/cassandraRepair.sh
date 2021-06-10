#!/bin/bash
# Test script to compare different looping strategy to perform full repair
# Shell loop on nodetool is expensive due to connection to JMX
# For a 3 node cluster with 256 vnodes there are 756 token range per keyspace
# a simple loop to perform 756 x $(nodetool status) takes ~ 9 minutes

\rm -f cassandra-nodetool-status.txt cassandra-nodetool-status.txt.perdc.[0-9]*

set -e

#method=perTokenRange
method=perPrimaryRange

nodetool=/opt/apache-cassandra-2.2.16/bin/nodetool

echo "Start script $0 with method :${method}"

count=0
if [[ "${method}" = "perTokenRange" ]]; then

    # Loop on all Datacenters
    for DC in `$nodetool status | grep "^Datacenter:" | sed "s/Datacenter: //g"` ; do
        echo "Repairing DC $DC"
        # Loop on all Keyspaces
        for KEYSPACE in `$nodetool tablestats | grep "^Keyspace" | sed "s/Keyspace: //g" | grep -v -w -e system -e system_traces -e system_distributed -e system_auth`; do
            echo "Repairing all token ranges for Keyspace $KEYSPACE"
            IFS=$'\n'
            # Loop on all token-ranges
            for line in `$nodetool describering $KEYSPACE | grep "endpoints:\[*" | cut -b 25-77 | sed -e 's/end_token://g' | sed -E 's/(\-?[0-9]+),[[:space:]](\-?[0-9]+).*/$nodetool repair -full -st \1 -et \2 -dc '${DC}' -- ${KEYSPACE}/g'`; do
                eval $line
                count=$(($count+1))
            done
            unset IFS
        done
    done

else
    $nodetool status > cassandra-nodetool-status.txt
    awk '/^Datacenter: /{i++}{print > "cassandra-nodetool-status.txt.perdc."i}' cassandra-nodetool-status.txt
    # Loop on all Datacenters
    for f in cassandra-nodetool-status.txt.* ; do 
        DC=`grep "^Datacenter:" $f | sed "s/Datacenter: //g"`
        # Loop on all nodes of this DC per Ip address of Up and Running nodes
        for node in `grep "^UN" $f | awk '{print $2}'`; do
            echo "Repairing primary range for Datacenter $DC and node $node"
            ## Warning: JMX port must be non local for this to work
            # $nodetool -h $node repair -pr -local -full
            ## Warning: ssh without password must be ok for this to work
            ssh -q $node $nodetool repair -pr -local -full
            count=$(($count+1))
        done
    done
    \rm -f cassandra-nodetool-status.txt cassandra-nodetool-status.txt.perdc.[0-9]*
    
fi

echo "number of nodetool repair command launched : $count"
echo "End"
