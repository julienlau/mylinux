#!/bin/bash
set -e

# name of the log file
mylog=$1
if [[ ! -e ${mylog} ]]; then
    echo "input file not found"
    exit 9
fi


## ONLY for all in STCS
# sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
# listks=`grep '^Keyspace' cas-stats.txt | grep -v -e ' system_traces$' -e ' system$' -e ' system_distributed$' -e ' system_schema$' -e ' system_auth$' | awk '{print $NF}'`
# cat /dev/null > stat.csv
# for ks in $listks ; do
#     sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
#     start=`grep -n "^Keyspace : $ks$" cas-stats.txt | head -1 | awk -F ':' '{print $1}'`
#     start=$(($start+6))
#     end=`grep -n '^Keyspace' cas-stats.txt  | grep -A 1 "Keyspace : $ks$" | tail -1 | awk -F ':' '{print $1}'`
#     end=$(($end-2))
#     echo "keyspace $ks : $start -> $end"
#     sed -i -n "$start,$end"p cas-stats.txt
#     # remove blank line
#     sed -i '/^[[:space:]]*$/d' cas-stats.txt
#     if [[ -z $linespertable ]]; then
#         linespertable=`grep -n "^[[:space:]]*Table" cas-stats.txt | head -2 |tail -1| awk -F ':' '{print $1}'`
#         linespertable=$(($linespertable-1))
#         echo "lines per table: $linespertable"
#     fi
#     split -l $linespertable cas-stats.txt tmp-split-
#     for f in $(ls tmp-split-*) ; do
#         hdr=$(grep -e "[a-z]" $f | awk -F ':' '{print $1","}')
#         hdr=$(echo $hdr | sed 's/,$//' | sed 's/ (index)//g')
#         line=`grep -e "[a-z]" $f | awk -F ':' '{ print $2 }' | awk '{ print $1 "," }'`
#         line=`echo $line | sed 's/,$//'`
#         if [[ -z $refhdr ]]; then
#             refhdr=$hdr
#         elif [[ "$hdr" != "$refhdr" ]]; then
#             echo "WARNING ! inconsistent headers for keyspace $ks and see file err-$ks-$f"
#             echo $line
#             echo $line |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
#             echo "$hdr"
#             echo $hdr |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
#             echo "$refhdr"
#             echo $refhdr |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
#             cp $f err-$ks-$f
#             exit 0
#         elif [[ $(grep -c "`echo $line | awk '{print $1}'`" stat.csv) -eq 0 ]] ; then
#             echo $line >> stat.csv
#         fi
#     done
#     echo $hdr > hdr.csv
#     rm -f tmp-split-*
# done

sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
listks=`grep '^Keyspace' cas-stats.txt | grep -v -e ' system_traces$' -e ' system$' -e ' system_distributed$' -e ' system_schema$' -e ' system_auth$' | awk '{print $NF}'`
cat /dev/null > stat.csv
for ks in $listks ; do
    sed '1,/===== tablestats =====/d;/===== tablehistograms/,$d' $mylog > cas-stats.txt
    start=`grep -n "^Keyspace : $ks$" cas-stats.txt | head -1 | awk -F ':' '{print $1}'`
    start=$(($start+6))
    end=`grep -n '^Keyspace' cas-stats.txt  | grep -A 1 "Keyspace : $ks$" | tail -1 | awk -F ':' '{print $1}'`
    end=$(($end-2))
    echo "keyspace $ks : $start -> $end"
    sed -i -n "$start,$end"p cas-stats.txt
    # remove blank line
    sed -i '/^[[:space:]]*$/d' cas-stats.txt
    if [[ -z $linespertable ]]; then
        linespertable=`grep -n "^[[:space:]]*Table" cas-stats.txt | head -2 |tail -1| awk -F ':' '{print $1}'`
        linespertable=$(($linespertable-1))
        echo "lines per table: $linespertable"
    fi
    split -l $linespertable cas-stats.txt tmp-split-
    for f in $(ls tmp-split-*) ; do
        hdr=$(grep -e "[a-z]" $f | awk -F ':' '{print $1","}')
        hdr=$(echo $hdr | sed 's/,$//' | sed 's/ (index)//g')
        line=`grep -e "[a-z]" $f | awk -F ':' '{ print $2 }' | awk '{ print $1 "," }'`
        line=`echo $line | sed 's/,$//'`
        if [[ -z $refhdr ]]; then
            refhdr=$hdr
        elif [[ "$hdr" != "$refhdr" ]]; then
            echo "WARNING ! inconsistent headers for keyspace $ks and see file err-$ks-$f"
            echo $line
            echo $line |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
            echo "$hdr"
            echo $hdr |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
            echo "$refhdr"
            echo $refhdr |awk '{print NR " " gsub(/[,]/, "")}' | awk '{ print $2 }'
            cp $f err-$ks-$f
            exit 0
        elif [[ $(grep -c "`echo $line | awk '{print $1}'`" stat.csv) -eq 0 ]] ; then
            echo $line >> stat.csv
        fi
    done
    echo $hdr > hdr.csv
    rm -f tmp-split-*
done

cat hdr.csv stat.csv > ${mylog}.csv
rm -f hdr.csv stat.csv
