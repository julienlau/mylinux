#!/bin/bash
set -e

# name of the log file
mylog=$1
if [[ ! -e ${mylog} ]]; then
    echo "input file not found"
    exit 9
fi

sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
listks=`grep '^Keyspace' cas-stats.txt | grep -v -e ' system_traces$' -e ' system$' -e ' system_distributed$' -e ' system_schema$' -e ' system_auth$' | awk '{print $NF}'`
cat /dev/null > stat.csv
for ks in $listks ; do
    sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
    start=`grep -n "^Keyspace : $ks$" cas-stats.txt | head -1 | awk -F ':' '{print $1}'`
    start=$(($start+6))
    end=`grep -n '^Keyspace' cas-stats.txt  | grep -A 1 "Keyspace : $ks$" | tail -1 | awk -F ':' '{print $1}'`
    end=$(($end-2))
    echo "$ks : $start,$end"
    sed -i -n "$start,$end"p cas-stats.txt
    # if cassandra 2.X : split -l 31 cas-stats.txt
    split -l 33 cas-stats.txt
    for f in $(ls x*) ; do
        hdr=`grep -e "[a-z]" $f | awk -F ':' '{print $1","}'`
        line=`grep -e "[a-z]" $f | awk -F ':' '{ print $2 }' | awk '{ print $1 "," }'`
        line=`echo $line | sed 's/,$//'`
        if [[ $(grep -c "`echo $line | awk '{print $1}'`" stat.csv) -eq 0 ]] ; then
            echo $line >> stat.csv
        fi
    done
    echo $hdr | sed 's/,$//' > hdr.csv
    rm -f x*
done
cat hdr.csv stat.csv > ${mylog}.csv
rm -f hdr.csv stat.csv
