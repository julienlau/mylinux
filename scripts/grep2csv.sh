#!/bin/bash

echo "need 3 inputs:"
echo "1/ grep pattern"
echo "2/ suffix for ls *.suffix"
echo "3/ name of the output csv file"

if [[ $# -ne 3 ]]; then
    exit 9
fi

greppattern='User time\|System time\|Maximum resident set size\|Elapsed\|^throughput\|^duration:\|Percent of CPU this job got:\|File system outputs:'
greppattern=$1
lssuffix=$2
csv=$3

for f in $(ls *.${lssuffix}) ; do 
    # header
    if [[ ! -e ${csv} ]]; then
        printf "filename," >> ${csv}
        grep "${greppattern}" ${f} | awk '{$NF=""; print $0}' | tr ',' '.' | tr -d '\r'| tr '\n' ',' | sed 's/,$//' >> ${csv}
        echo "" >> ${csv}
    fi
    printf "${f}," >> ${csv}
    grep "${greppattern}" ${f} | awk '{print $NF}'  | tr ',' '.' | tr -d "'" | tr -d '[a-z][A-Z]' | tr -d "%" | tr -d '\r' | tr '\n' ',' | sed 's/,$//' >> ${csv}
    echo "" >> ${csv}
done
