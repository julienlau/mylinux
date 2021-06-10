#!/bin/bash

wdir=$(pwd)
host=`hostname`

tmpstr=${wdir}/tmp_$(date '+%m%d%y')_$(date '+%H%M%S')_$$.log
flog=${wdir}/sysbench_${host}_$(date '+%m%d%y')_$(date '+%H%M%S')_$$.log
fsummary=${wdir}/sysbench_summary_${host}_$(date '+%m%d%y')_$(date '+%H%M%S')_$$.log

disktool=fio
diskonly=0
diskclean=1
runtimefio=60

hostname > ${flog}
uname -a >> ${flog}
date >> ${flog}
date > ${fsummary}

ncore=`grep -c ^processor /proc/cpuinfo`
ncorepp=`echo ${ncore} | awk '{n=$1 ; print n*16 ; }'`
gbsizemem=`awk '/MemTotal/ {print int($2/1024/1024*5)}' /proc/meminfo`

if [[ $# -gt 0 ]]; then
    listpath=$@
else
    listpath=$(pwd)
fi

if [[ $diskonly -ne 1 ]]; then

    echo "Hardware parameters : " | tee -a ${flog}
    echo "ncore=$ncore" | tee -a ${flog}
    echo "ncorepp=$ncorepp" | tee -a ${flog}
    echo "listpath=$listpath" | tee -a ${flog}

    echo "sysbench --threads=1 --time=60 --cpu-max-prime=20000 cpu run" | tee ${tmpstr}
    sysbench --threads=1 --time=60 --cpu-max-prime=20000 cpu run | tee ${tmpstr}
    if [[ $? -ne 0 ]]; then echo "error "; exit 9; fi

    score=`grep 'events per second:' ${tmpstr} |awk '{print $NF}'`
    echo "$host cpu single $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    echo "sysbench --threads=${ncore} --time=60 --cpu-max-prime=20000 cpu run"
    score=`grep 'events per second:' ${tmpstr} |awk '{print $NF}'`
    echo "$host cpu all $score" >> ${fsummary}
    sysbench --threads=${ncore} --time=60 --cpu-max-prime=20000 cpu run | tee ${tmpstr}
    cat ${tmpstr} >> ${flog}

    echo "sysbench --threads=${ncorepp} --time=60 --cpu-max-prime=20000 cpu run"
    sysbench --threads=${ncorepp} --time=60 --cpu-max-prime=20000 cpu run | tee ${tmpstr}
    score=`grep 'events per second:' ${tmpstr} |awk '{print $NF}'`
    echo "$host cpu over $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    sysbench --num-threads=1 mutex run | tee ${tmpstr}
    score=`grep 'total time:' ${tmpstr} |awk '{print $NF}'`
    echo "$host mutex single $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    sysbench --num-threads=${ncore} mutex run | tee ${tmpstr}
    score=`grep 'total time:' ${tmpstr} |awk '{print $NF}'`
    echo "$host mutex all $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    echo "RAM read" | tee ${tmpstr}
    sysbench --memory-block-size=1M --memory-scope=global --memory-total-size=${gbsizemem}G --memory-oper=read memory run | tee ${tmpstr}
    score=`grep 'Total operations:' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram readops $score" >> ${fsummary}
    score=`grep 'MiB transferred (' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram readbandwidth $score" >> ${fsummary}
    score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
    echo "$host ram latency95 $score" >> ${fsummary}
    score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
    echo "$host ram latencymax $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    echo "RAM write" | tee ${tmpstr}
    sysbench --memory-block-size=1M --memory-scope=global --memory-total-size=${gbsizemem}G --memory-oper=write memory run | tee ${tmpstr}
    score=`grep 'Total operations:' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram writeops $score" >> ${fsummary}
    score=`grep 'MiB transferred (' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram writebandwidth $score" >> ${fsummary}
    score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
    echo "$host ram latency95 $score" >> ${fsummary}
    score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
    echo "$host ram latencymax $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}

    echo "RAM concurrent" | tee ${tmpstr}
    sysbench --threads=${ncorepp} --memory-total-size=${gbsizemem}G memory run
    score=`grep 'Total operations:' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram concurops $score" >> ${fsummary}
    score=`grep 'MiB transferred (' ${tmpstr} |awk '{print $4}' | tr -d '('`
    echo "$host ram concurbandwidth $score" >> ${fsummary}
    score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
    echo "$host ram latency95 $score" >> ${fsummary}
    score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
    echo "$host ram latencymax $score" >> ${fsummary}
    cat ${tmpstr} >> ${flog}
fi

for path in ${listpath} ; do
    \ls -d ${path}
    if [[ $? -ne 0 ]]; then echo "error path ${path} not found"; exit 9; fi

    diskname=`df ${path} | tail -1 | awk '{print $1}'`

    lsblk -o NAME,KNAME,MAJ:MIN,RM,SIZE,RO,TYPE,MOUNTPOINT ${diskname} | tee -a ${flog}
    if [[ $? -ne 0 ]]; then echo "error lsblk ${disk} "; exit 9; fi

    hdparm -I ${diskname} | tee -a ${flog} 2>&1
    if [[ $? -ne 0 ]]; then echo "error hdparm ${disk} "; exit 9; fi

    udevadm info -q all -n ${diskname} | tee -a ${flog} 2>&1
    sudo lshw -c storage | tee -a ${flog} 2>&1
    sudo lshw -c disk | tee -a ${flog} 2>&1

    gbsizefile=`awk '/MemTotal/ {print 2*int($2/1024/1024)}' /proc/meminfo`
    gbdiskfree=`df -m ${path} | tail -1 | awk '{print int($4/1024-1)}'`
    if [[ ! -z `which python 2>/dev/null` ]] ; then
        gbsizefile=`python -c "print min(16,$gbsizefile,$gbdiskfree)"`
    else
        gbsizefile=`df -m ${path} | tail -1 | awk '{print int($4/1024/10-1)}'`
    fi

    echo "gbsizemem=$gbsizemem" | tee -a ${flog}
    echo "gbsizefile=$gbsizefile" | tee -a ${flog}

    if [[ ${disktool} = "fio" ]] ; then
        # direct: Set to true for non-buffered IO. This implies files are opened with O_DIRECT flag which results in IOs bypassing host cache. direct=1 for read
        # iodepth or numjobs (in case of fsync=1) should be increased if disk util is not near 100%
        # fio hdr to be used to parse output of -minimal option:
        # terse_version;fio_version;jobname;groupid;error;READ_kb;READ_bandwidth;READ_IOPS;READ_runtime;READ_Slat_min;READ_Slat_max;READ_Slat_mean;READ_Slat_dev;READ_Clat_max;READ_Clat_min;READ_Clat_mean;READ_Clat_dev;READ_clat_pct01;READ_clat_pct02;READ_clat_pct03;READ_clat_pct04;READ_clat_pct05;READ_clat_pct06;READ_clat_pct07;READ_clat_pct08;READ_clat_pct09;READ_clat_pct10;READ_clat_pct11;READ_clat_pct12;READ_clat_pct13;READ_clat_pct14;READ_clat_pct15;READ_clat_pct16;READ_clat_pct17;READ_clat_pct18;READ_clat_pct19;READ_clat_pct20;READ_tlat_min;READ_lat_max;READ_lat_mean;READ_lat_dev;READ_bw_min;READ_bw_max;READ_bw_agg_pct;READ_bw_mean;READ_bw_dev;WRITE_kb;WRITE_bandwidth;WRITE_IOPS;WRITE_runtime;WRITE_Slat_min;WRITE_Slat_max;WRITE_Slat_mean;WRITE_Slat_dev;WRITE_Clat_max;WRITE_Clat_min;WRITE_Clat_mean;WRITE_Clat_dev;WRITE_clat_pct01;WRITE_clat_pct02;WRITE_clat_pct03;WRITE_clat_pct04;WRITE_clat_pct05;WRITE_clat_pct06;WRITE_clat_pct07;WRITE_clat_pct08;WRITE_clat_pct09;WRITE_clat_pct10;WRITE_clat_pct11;WRITE_clat_pct12;WRITE_clat_pct13;WRITE_clat_pct14;WRITE_clat_pct15;WRITE_clat_pct16;WRITE_clat_pct17;WRITE_clat_pct18;WRITE_clat_pct19;WRITE_clat_pct20;WRITE_tlat_min;WRITE_lat_max;WRITE_lat_mean;WRITE_lat_dev;WRITE_bw_min;WRITE_bw_max;WRITE_bw_agg_pct;WRITE_bw_mean;WRITE_bw_dev;CPU_user;CPU_sys;CPU_csw;CPU_mjf;PU_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops;disk_read_merges;disk_write_merges;disk_read_ticks;write_ticks;disk_queue_time;disk_utilization

        if [[ ! -z `which ioping 2>/dev/null` ]] ; then
            echo "Latency" | tee -a ${flog}
            ioping -c 100 . | tee ${flog}
        fi

        if [[ `dirname ${path}` = "/dev" ]]; then
            fiodata=${diskname}
            diskclean=0
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "WARN"
            echo "Warning raw disk write will be performed !!!"
            sleep 10
        else
            \cd ${path}
            if [[ $? -ne 0 ]]; then echo "error "; exit 9; fi
            fiodata=./fio-tempfile-$(uuidgen).fio
        fi

        echo "terse_version;fio_version;jobname;groupid;error;READ_kb;READ_bandwidth;READ_IOPS;READ_runtime;READ_Slat_min;READ_Slat_max;READ_Slat_mean;READ_Slat_dev;READ_Clat_max;READ_Clat_min;READ_Clat_mean;READ_Clat_dev;READ_clat_pct01;READ_clat_pct02;READ_clat_pct03;READ_clat_pct04;READ_clat_pct05;READ_clat_pct06;READ_clat_pct07;READ_clat_pct08;READ_clat_pct09;READ_clat_pct10;READ_clat_pct11;READ_clat_pct12;READ_clat_pct13;READ_clat_pct14;READ_clat_pct15;READ_clat_pct16;READ_clat_pct17;READ_clat_pct18;READ_clat_pct19;READ_clat_pct20;READ_tlat_min;READ_lat_max;READ_lat_mean;READ_lat_dev;READ_bw_min;READ_bw_max;READ_bw_agg_pct;READ_bw_mean;READ_bw_dev;WRITE_kb;WRITE_bandwidth;WRITE_IOPS;WRITE_runtime;WRITE_Slat_min;WRITE_Slat_max;WRITE_Slat_mean;WRITE_Slat_dev;WRITE_Clat_max;WRITE_Clat_min;WRITE_Clat_mean;WRITE_Clat_dev;WRITE_clat_pct01;WRITE_clat_pct02;WRITE_clat_pct03;WRITE_clat_pct04;WRITE_clat_pct05;WRITE_clat_pct06;WRITE_clat_pct07;WRITE_clat_pct08;WRITE_clat_pct09;WRITE_clat_pct10;WRITE_clat_pct11;WRITE_clat_pct12;WRITE_clat_pct13;WRITE_clat_pct14;WRITE_clat_pct15;WRITE_clat_pct16;WRITE_clat_pct17;WRITE_clat_pct18;WRITE_clat_pct19;WRITE_clat_pct20;WRITE_tlat_min;WRITE_lat_max;WRITE_lat_mean;WRITE_lat_dev;WRITE_bw_min;WRITE_bw_max;WRITE_bw_agg_pct;WRITE_bw_mean;WRITE_bw_dev;CPU_user;CPU_sys;CPU_csw;CPU_mjf;PU_minf;iodepth_1;iodepth_2;iodepth_4;iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;disk_read_iops;disk_write_iops;disk_read_merges;disk_write_merges;disk_read_ticks;write_ticks;disk_queue_time;disk_utilization" | tee -a ${flog}
        
        # echo "IO profile HDFS" 
        # fio --minimal --name write_hdfs --filename=${fiodata} --rw=randwrite --gtod_reduce=1 --size=${gbsizefile}g--io_size=1024g --blocksize=128m --ioengine=libaio --iodepth=1 --numjobs=6 --runtime=60 --group_reporting | tee -a ${flog}
        # if [[ $? -ne 0 ]]; then echo "error "; exit 9; fi
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "IO profile Zookeeper"
        # fio --minimal --name write_zookeeper --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --gtod_reduce=1 --filename=${fiodata} --bs=4k --iodepth=32 --numjobs=1 --size=${gbsizefile}g --runtime=${runtimefio} --rw=randwrite --group_reporting | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Seq Read Only"
        # fio --minimal --randrepeat=1 --ioengine=libaio --direct=1 --invalidate=1 --gtod_reduce=1 --name=randr_4m --filename=${fiodata} --bs=4m --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=read | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Seq Write Only"
        # fio --minimal --randrepeat=1 --ioengine=libaio --direct=1 --invalidate=1 --gtod_reduce=1 --name=randw_4m_qd32 --filename=${fiodata} --bs=4m --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=write | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random Read Only"
        # fio --minimal --randrepeat=1 --ioengine=libaio --direct=1 --invalidate=1 --gtod_reduce=1 --name=randr_4k --filename=${fiodata} --bs=4k --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randread | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random Write Only"
        # fio --minimal --randrepeat=1 --ioengine=libaio --direct=1 --invalidate=1 --gtod_reduce=1 --name=randw_4k_qd32 --filename=${fiodata} --bs=4k --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randwrite | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random Write Only using fsync + QD=1"
        # fio --minimal --randrepeat=1 --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --gtod_reduce=1 --name=randw_4k_qd1_fsync --filename=${fiodata} --bs=4k --iodepth=1 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randwrite | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random Write Only using fsync"
        # fio --minimal --randrepeat=1 --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --gtod_reduce=1 --name=randw_4k_qd32_fsync --filename=${fiodata} --bs=4k --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randwrite | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random ReadWrite using no fsync"
        # fio --minimal --randrepeat=1 --ioengine=libaio --direct=1 --invalidate=1 --gtod_reduce=1 --name=randrw_4k_qd32 --filename=${fiodata} --bs=4k --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randrw --rwmixread=75 | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        # echo "Random ReadWrite using fsync"
        # fio --minimal --fsync=1 --randrepeat=1 --ioengine=libaio --fsync=1 --direct=1 --invalidate=1 --gtod_reduce=1 --name=randrw_4k_qd32_fsync --filename=${fiodata} --bs=4k --iodepth=32 --size=${gbsizefile}g --runtime=${runtimefio} --readwrite=randrw --rwmixread=75 | tee -a ${flog}
        # if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Linear read:"
        fio --minimal -ioengine=libaio -direct=1 -invalidate=1 -name=linear_read -bs=4M -iodepth=32 -rw=read -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Linear write: "
        fio --minimal -ioengine=libaio -direct=1 -invalidate=1 -name=linear_write -bs=4M -iodepth=32 -rw=write -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Peak parallel random read: "
        fio --minimal -ioengine=libaio -direct=1 -invalidate=1 -name=parallel_rand_read -bs=4k -iodepth=128 -rw=randread -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Single-threaded read latency: "
        fio --minimal -ioengine=libaio -fsync=1 -direct=1 -invalidate=1 -name=single_thread_latency -bs=4k -iodepth=1 -rw=randread -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Peak parallel random write: "
        fio --minimal -ioengine=libaio -direct=1 -invalidate=1 -name=parallel_rand_write -bs=4k -iodepth=128 -rw=randwrite -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi

        echo "Journal write latency: "
        #Also try it with -fsync=1 instead of -sync=1 and write down the worst result, because sometimes one of sync or fsync is ignored by messy hardware.
        fio --minimal -ioengine=libaio -fsync=1 -direct=1 -invalidate=1 -name=journal_write_latency_fsync -bs=4k -iodepth=1 -rw=write -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi
        fio --minimal -ioengine=libaio -sync=1 -direct=1 -invalidate=1 -name=journal_write_latency_sync -bs=4k -iodepth=1 -rw=write -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi


        echo "Single-threaded random write latency: "
        fio --minimal -ioengine=libaio -fsync=1 -direct=1 -invalidate=1 -name=single_thread_rand_latency_fsync -bs=4k -iodepth=1 -rw=randwrite -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi
        fio --minimal -ioengine=libaio -sync=1 -direct=1 -invalidate=1 -name=single_thread_rand_latency_sync -bs=4k -iodepth=1 -rw=randwrite -runtime=${runtimefio} -filename=${fiodata} --size=${gbsizefile}g | tee -a ${flog}
        if [[ ${diskclean} -eq 1 ]]; then rm -f ${fiodata} ; fi


    else

        ##The size of the file depends on the amount of RAM in the system, so if you have 32GB RAM installed, the test file needs to be larger than 32GB
        echo "sysbench --file-total-size=${gbsizefile}G --file-num=64 fileio prepare" | tee ${tmpstr}
        sysbench --file-total-size=${gbsizefile}G --file-num=64 fileio prepare | tee ${tmpstr}
        score=`grep 'bytes written in' ${tmpstr} |awk '{print $7}' | tr -d '('`
        echo "$host $diskname diskprep $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Sequential Read Only" | tee ${tmpstr}
        sysbench --file-total-size=${gbsizefile}G --file-num=64 --file-test-mode=seqrd --file-block-size=4096 --time=60 --max-requests=0 --threads=1 fileio run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskseqread_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskseqread_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskseqread_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskseqread_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskseqread_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskseqread_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskseqread_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Random Read Only" | tee ${tmpstr}
        sysbench --file-total-size=${gbsizefile}G --file-num=64 --file-test-mode=rndrd --file-block-size=4096 --time=60 --max-requests=0 --threads=1 fileio run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandread_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandread_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandread_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandread_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandread_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskrandread_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskrandread_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Random Write using no fsync (Should show the highest potential random writes)" | tee ${tmpstr}
        sysbench --test=fileio --file-total-size=${gbsizefile}G --file-test-mode=rndwr --file-block-size=4096 --time=60 --max-requests=0 --threads=1 --file-num=64 --file-io-mode=async --file-extra-flags=direct --file-fsync-freq=0 run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandasyncw_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandasyncw_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandasyncw_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandasyncw_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandasyncw_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskrandasyncw_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskrandasyncw_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Random Write using default fsync (Should show typical fsync behavior)" | tee ${tmpstr}
        sysbench --test=fileio --file-total-size=${gbsizefile}G --file-test-mode=rndwr --file-block-size=4096 --time=60 --max-requests=0 --threads=1 --file-num=64 --file-io-mode=async --file-extra-flags=direct --file-fsync-freq=0 run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandwrite_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandwrite_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandwrite_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandwrite_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandwrite_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskrandwrite_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskrandwrite_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Random Write using all fsync" | tee ${tmpstr}
        sysbench --test=fileio --file-total-size=${gbsizefile}G --file-test-mode=rndwr --file-block-size=4096 --time=60 --max-requests=0 --threads=1 --file-num=64 --file-io-mode=sync --file-extra-flags=direct --file-fsync-all=on run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandfsync_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandfsync_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandfsync_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandfsync_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskrandfsync_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskrandfsync_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskrandfsync_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        echo "Mixed Random Read and Write" | tee ${tmpstr}
        sysbench --file-total-size=${gbsizefile}G --file-num=64 --file-test-mode=rndrw --file-block-size=4096 --time=60 --max-requests=0 --threads=${ncorepp} fileio run | tee ${tmpstr}
        score=`grep 'riops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskmixed_riops $score" >> ${fsummary}
        score=`grep 'wiops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskmixed_wiops $score" >> ${fsummary}
        score=`grep 'fops:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskmixed_siops $score" >> ${fsummary}
        score=`grep 'read, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskmixed_rtput $score" >> ${fsummary}
        score=`grep 'written, MiB/s:' ${tmpstr} |awk '{print $NF}'`
        echo "$host $diskname diskmixed_wtput $score" >> ${fsummary}
        score=`grep ' 95th percentile: ' ${tmpstr} |awk '{print $3}'`
        echo "$host $diskname diskmixed_lat95 $score" >> ${fsummary}
        score=`grep ' max: ' ${tmpstr} |awk '{print $2}'`
        echo "$host $diskname diskmixed_lat $score" >> ${fsummary}
        cat ${tmpstr} >> ${flog}

        # echo "RAND WRITE 1 - 16 thread" | tee ${tmpstr}
        # for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndwr --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=1 run; done; sleep 10; for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndwr --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=4 run; done; sleep 10; for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndwr --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=8 run; done; sleep 10; for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndwr --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=16 run; done;

        # echo "RAND READ 1 - 16 thread"
        # for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndrd --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=1 run; done; sleep 10;for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndrd --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=4 run; done; sleep 10;for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndrd --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=8 run; done; sleep 10;for each in {1..3} ; do sysbench --test=fileio --file-total-size=5G --file-test-mode=rndrd --time=60 --max-requests=0 --file-block-size=4K --file-num=64 --threads=16 run; done; sleep 10;

        sysbench --file-total-size=${gbsizefile}G --file-num=64 fileio cleanup

    fi
done

rm -f ${tmpstr}

\cd ${wdir}
echo "see files ${flog} ${fsummary}"
