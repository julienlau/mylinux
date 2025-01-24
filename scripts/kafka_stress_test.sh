#!/usr/bin/bash

export dbg=0
export mode=normal # normal or stress
fsummary=summary.dat
cat /dev/null > $fsummary

if [[ ${dbg} > 0 ]]; then
    set -x
    set -e
fi

# cd /opt && rsync -rtva -e ssh kafka-1.mycluster.private:/etc/kafka .
#export kafkadir=/opt/kafka
export kafkadir=/opt/mycluster/kk00/kafka
#export zkconnect=kafka-1.mycluster.private:2181,kafka-2.mycluster.private:2181,kafka-3.mycluster.private:2181  
export zkconnect=mscu-zk00-vm-1.mydomain.mycluster:2181,mscu-zk00-vm-2.mydomain.mycluster:2181,mscu-zk00-vm-3.mydomain.mycluster:2181  
export kafkaconnect=mscu-kk00-vm-1.mydomain.mycluster:9097,mscu-kk00-vm-2.mydomain.mycluster:9097,mscu-kk00-vm-3.mydomain.mycluster:9097,mscu-kk00-vm-4.mydomain.mycluster:9097,mscu-kk00-vm-5.mydomain.mycluster:9097
export INCLUDE_TEST_JARS=true

export ipzk=`ping -c1 mscu-zk00-vm-1.mydomain.mycluster| head -1 | awk '{print $3}' | tr -d '()'`
export myip=`ip route get $ipzk 2>/dev/null | awk '{ for(i=1; i<NF; i++) { if($i == "src") {print $(i+1); exit} } }'`

export KAFKA_HEAP_OPTS="-Xmx16G"

#bin/zkCli.sh -server ${zkconnect}

export numrecords=60111000
if [[ ${mode} = "stress" ]]; then
    export numrecords=600100100
fi

# Kafka supports 4 compression codecs: none, gzip, lz4 and snappy
# ack=-1 means synchronous, ack=1 means asynchronous
replication=5; part=100; comp=none; ack=-1

for replication in 1 5 ; do
    for part in 1 5 36 100 ; do
        for comp in none lz4 ; do
            for ack in -1 1 ; do

                date 

                echo "TEST : ack=${ack} partitions=${part} replication=${replication} compression=${comp}"

                echo "Create topic benchmark_a${ack}_p${part}_r${replication}_comp${comp}"
                ${kafkadir}/bin/kafka-topics.sh --create \
                    --zookeeper ${zkconnect} \
                    --replication-factor ${replication} \
                    --partitions ${part} \
                    --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp}
                echo "status=$?"

                echo "Consumer Throughput:"
                timeout -k 20 2000s ${kafkadir}/bin/kafka-consumer-perf-test.sh --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp} \
                    --broker-list ${kafkaconnect}\
                    --messages ${numrecords} \
                    --threads ${part} --print-metrics --show-detailed-stats | tee consumer_benchmark_a${ack}_p${part}_r${replication}_comp${comp}.log &
                echo "status=$?"

                echo "Producer Throughput"
                timeout -k 20 2000s ${kafkadir}/bin/kafka-producer-perf-test.sh --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp} \
                    --num-records ${numrecords} \
                    --record-size 500 \
                    --throughput 2000111000 \
                    --producer-props \
                    acks=${ack} \
                    bootstrap.servers=${kafkaconnect} \
                    buffer.memory=67108864 \
                    compression.type=${comp} \
                    batch.size=131072 \
                    linger.ms=0 \
                    --print-metrics | tee benchmark_a${ack}_p${part}_r${replication}_comp${comp}.log
                echo "benchmark_a${ack}_p${part}_r${replication}_comp${comp} status=$?"

                echo "Delete topic"
                ${kafkadir}/bin/kafka-topics.sh --delete --zookeeper ${zkconnect} --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp}

            done
        done
    done
done

echo "TEST Effect of message size"
comp=none
ack=1
part=3
replication=3

${kafkadir}/bin/kafka-topics.sh --create \
    --zookeeper ${zkconnect} \
    --replication-factor ${replication} \
    --partitions ${part} \
    --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp}
echo "status=$?"

for i in 10 100 1000 10000 100000; do
    echo ""
    echo "RECORD SIZE=$i byte"
    timeout -k 20 2000s ${kafkadir}/bin/kafka-producer-perf-test.sh --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp} \
        --num-records $((1000*1024*1024/$i)) \
        --record-size $i \
        --throughput $((1000*1024*1024/$i)) \
        --producer-props \
        acks=${ack} \
        bootstrap.servers=${kafkaconnect} \
        buffer.memory=67108864 \
        compression.type=none \
        batch.size=128000 --print-metrics | tee -a benchmark_record_size.log
    echo "status=$?"
done;

${kafkadir}/bin/kafka-topics.sh --delete --zookeeper ${zkconnect} --topic benchmark_a${ack}_p${part}_r${replication}_comp${comp}
echo "status=$?"

## Delete all topics
list="benchmark_a-1_p1_r1_compnone benchmark_a1_p1_r1_compnone benchmark_a-1_p1_r1_complz4 benchmark_a1_p1_r1_complz4 benchmark_a-1_p3_r1_compnone benchmark_a1_p3_r1_compnone benchmark_a-1_p3_r1_complz4 benchmark_a1_p3_r1_complz4 benchmark_a-1_p12_r1_compnone benchmark_a1_p12_r1_compnone benchmark_a-1_p12_r1_complz4 benchmark_a1_p12_r1_complz4 benchmark_a-1_p36_r1_compnone benchmark_a1_p36_r1_compnone benchmark_a-1_p36_r1_complz4 benchmark_a1_p36_r1_complz4 benchmark_a-1_p1_r3_compnone benchmark_a1_p1_r3_compnone benchmark_a-1_p1_r3_complz4 benchmark_a1_p1_r3_complz4 benchmark_a-1_p3_r3_compnone benchmark_a1_p3_r3_compnone benchmark_a-1_p3_r3_complz4 benchmark_a1_p3_r3_complz4 benchmark_a-1_p12_r3_compnone benchmark_a1_p12_r3_compnone benchmark_a-1_p12_r3_complz4 benchmark_a1_p12_r3_complz4 benchmark_a-1_p36_r3_compnone benchmark_a1_p36_r3_compnone benchmark_a-1_p36_r3_complz4 benchmark_a1_p36_r3_complz4"
if [[ ${dbg} > 0 ]]; then 
    for topic in $list ; do ${kafkadir}/bin/kafka-topics.sh --delete --if-exists --zookeeper ${zkconnect} --topic ${topic}; done
fi

for flog in $(ls benchmark*.log); do 
    echo ""; echo "Summary ${flog} :"
    stats=`tail -200 ${flog} | grep "^[0-9]" | tail -1`
    echo $stats
    zdate=`stat -c "%y" $flog | tr -s ' ' '_'`
    throughput=`echo $stats | awk -F',' '{print $2}'| awk '{print $3}' | tr -d '('`
    lat_max=`echo $stats | awk -F',' '{print $4}'| awk '{print $1}'`
    lat_p99=`echo $stats | awk -F',' '{print $7}'| awk '{print $1}'`
    echo "| $zdate | $flog | $throughput | $lat_max | $lat_p99 |" >> $fsummary
    grep -i error ${flog}
done
