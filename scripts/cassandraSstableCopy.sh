#!/bin/bash

# Avoid naming collision and overwrite on copy between source and destination by incrementing sstable ID number if necessary.
# comparison of files based on filename and size&content of -Data.db
# Comparison of Data.db content may be time consuming
# Thanks to file content comparison, this script can be launched numerous times without duplicating all sstables at each run, ie. in an incremental merge fashion.
# This can be useful to clone a table from a snapshot.
#
# inputs :
# 1/ source sstable, can be a single file or a directory containing sstables
# 2/ destination path
#
# Usage: cassandraSstableCopy.sh lb-9-big-Data.db /tmp
# From a source sstable filename retrieve all linked cassandra files and 
# copy them to the destination.
# All linked files for lb-9-big-Data.db will be all the files sharing the prefix 'lb-9-big*'
# Preserve source file attributes (timestamps).
#
#
#
# Example:
# ls -la /tmp/toto .
# .:
# total 390800
# drwxr-xr-x 2 cassandra data      4096 May 31 17:32 .
# drwxr-xr-x 3 cassandra data        27 May 31 17:32 ..
# -rw-r--r-- 1 cassandra data     26699 Apr  8 18:30 lb-1-big-CompressionInfo.db
# -rw-r--r-- 1 cassandra data 173010823 Apr  8 18:30 lb-1-big-Data.db
# -rw-r--r-- 1 cassandra data        10 Apr  8 18:30 lb-1-big-Digest.adler32
# -rw-r--r-- 1 cassandra data   1249984 Apr  8 18:30 lb-1-big-Filter.db
# -rw-r--r-- 1 cassandra data  25888242 Apr  8 18:30 lb-1-big-Index.db
# -rw-r--r-- 1 cassandra data      9907 Apr  8 18:30 lb-1-big-Statistics.db
# -rw-r--r-- 1 cassandra data    186756 Apr  8 18:30 lb-1-big-Summary.db
# -rw-r--r-- 1 cassandra data        94 Apr  8 18:30 lb-1-big-TOC.txt
# -rw-r--r-- 1 cassandra data     26595 Apr 21 09:34 lb-2-big-CompressionInfo.db
# -rw-r--r-- 1 cassandra data 172498348 Apr 21 09:34 lb-2-big-Data.db
# -rw-r--r-- 1 cassandra data        10 Apr 21 09:34 lb-2-big-Digest.adler32
# -rw-r--r-- 1 cassandra data   1245224 Apr 21 09:34 lb-2-big-Filter.db
# -rw-r--r-- 1 cassandra data  25789701 Apr 21 09:34 lb-2-big-Index.db
# -rw-r--r-- 1 cassandra data      9907 Apr 21 09:34 lb-2-big-Statistics.db
# -rw-r--r-- 1 cassandra data    186027 Apr 21 09:34 lb-2-big-Summary.db
# -rw-r--r-- 1 cassandra data        94 Apr 21 09:34 lb-2-big-TOC.txt
# -rw-r--r-- 1 cassandra data        50 May 31 17:32 manifest.json
#
# /tmp/toto:
# total 0
# drwxrwxr-x 1 jlu  jlu     0 Jun 10 15:52 .
# drwxrwxrwt 1 root root 2598 Jun 10 15:52 ..
#
# [jlu@linux-gp75]> ~/src/mylinux/scripts/cassandraSstableCopy.sh . /tmp/toto
# Copying all sstables from the source directory including sub-directories
#
# sstablecopyfile ./lb-1-big-Data.db /tmp/toto//.
# cp -a -i ./lb-1-big-CompressionInfo.db /tmp/toto/./
# cp -a -i ./lb-1-big-Data.db /tmp/toto/./
# cp -a -i ./lb-1-big-Digest.adler32 /tmp/toto/./
# cp -a -i ./lb-1-big-Filter.db /tmp/toto/./
# cp -a -i ./lb-1-big-Index.db /tmp/toto/./
# cp -a -i ./lb-1-big-Statistics.db /tmp/toto/./
# cp -a -i ./lb-1-big-Summary.db /tmp/toto/./
# cp -a -i ./lb-1-big-TOC.txt /tmp/toto/./
#
# sstablecopyfile ./lb-2-big-Data.db /tmp/toto//.
# cp -a -i ./lb-2-big-CompressionInfo.db /tmp/toto/./
# cp -a -i ./lb-2-big-Data.db /tmp/toto/./
# cp -a -i ./lb-2-big-Digest.adler32 /tmp/toto/./
# cp -a -i ./lb-2-big-Filter.db /tmp/toto/./
# cp -a -i ./lb-2-big-Index.db /tmp/toto/./
# cp -a -i ./lb-2-big-Statistics.db /tmp/toto/./
# cp -a -i ./lb-2-big-Summary.db /tmp/toto/./
# cp -a -i ./lb-2-big-TOC.txt /tmp/toto/./
#
# [jlu@linux-gp75]> ls -la /tmp/toto .
# .:
# total 390800
# drwxr-xr-x 2 cassandra data      4096 May 31 17:32 .
# drwxr-xr-x 3 cassandra data        27 May 31 17:32 ..
# -rw-r--r-- 1 cassandra data     26699 Apr  8 18:30 lb-1-big-CompressionInfo.db
# -rw-r--r-- 1 cassandra data 173010823 Apr  8 18:30 lb-1-big-Data.db
# -rw-r--r-- 1 cassandra data        10 Apr  8 18:30 lb-1-big-Digest.adler32
# -rw-r--r-- 1 cassandra data   1249984 Apr  8 18:30 lb-1-big-Filter.db
# -rw-r--r-- 1 cassandra data  25888242 Apr  8 18:30 lb-1-big-Index.db
# -rw-r--r-- 1 cassandra data      9907 Apr  8 18:30 lb-1-big-Statistics.db
# -rw-r--r-- 1 cassandra data    186756 Apr  8 18:30 lb-1-big-Summary.db
# -rw-r--r-- 1 cassandra data        94 Apr  8 18:30 lb-1-big-TOC.txt
# -rw-r--r-- 1 cassandra data     26595 Apr 21 09:34 lb-2-big-CompressionInfo.db
# -rw-r--r-- 1 cassandra data 172498348 Apr 21 09:34 lb-2-big-Data.db
# -rw-r--r-- 1 cassandra data        10 Apr 21 09:34 lb-2-big-Digest.adler32
# -rw-r--r-- 1 cassandra data   1245224 Apr 21 09:34 lb-2-big-Filter.db
# -rw-r--r-- 1 cassandra data  25789701 Apr 21 09:34 lb-2-big-Index.db
# -rw-r--r-- 1 cassandra data      9907 Apr 21 09:34 lb-2-big-Statistics.db
# -rw-r--r-- 1 cassandra data    186027 Apr 21 09:34 lb-2-big-Summary.db
# -rw-r--r-- 1 cassandra data        94 Apr 21 09:34 lb-2-big-TOC.txt
# -rw-r--r-- 1 cassandra data        50 May 31 17:32 manifest.json
#
# /tmp/toto:
# total 390792
# drwxrwxr-x 1 jlu  jlu        632 Jun 10 15:53 .
# drwxrwxrwt 1 root root      2598 Jun 10 15:52 ..
# -rw-r--r-- 1 jlu  data     26699 Apr  8 18:30 lb-1-big-CompressionInfo.db
# -rw-r--r-- 1 jlu  data 173010823 Apr  8 18:30 lb-1-big-Data.db
# -rw-r--r-- 1 jlu  data        10 Apr  8 18:30 lb-1-big-Digest.adler32
# -rw-r--r-- 1 jlu  data   1249984 Apr  8 18:30 lb-1-big-Filter.db
# -rw-r--r-- 1 jlu  data  25888242 Apr  8 18:30 lb-1-big-Index.db
# -rw-r--r-- 1 jlu  data      9907 Apr  8 18:30 lb-1-big-Statistics.db
# -rw-r--r-- 1 jlu  data    186756 Apr  8 18:30 lb-1-big-Summary.db
# -rw-r--r-- 1 jlu  data        94 Apr  8 18:30 lb-1-big-TOC.txt
# -rw-r--r-- 1 jlu  data     26595 Apr 21 09:34 lb-2-big-CompressionInfo.db
# -rw-r--r-- 1 jlu  data 172498348 Apr 21 09:34 lb-2-big-Data.db
# -rw-r--r-- 1 jlu  data        10 Apr 21 09:34 lb-2-big-Digest.adler32
# -rw-r--r-- 1 jlu  data   1245224 Apr 21 09:34 lb-2-big-Filter.db
# -rw-r--r-- 1 jlu  data  25789701 Apr 21 09:34 lb-2-big-Index.db
# -rw-r--r-- 1 jlu  data      9907 Apr 21 09:34 lb-2-big-Statistics.db
# -rw-r--r-- 1 jlu  data    186027 Apr 21 09:34 lb-2-big-Summary.db
# -rw-r--r-- 1 jlu  data        94 Apr 21 09:34 lb-2-big-TOC.txt
# [jlu@linux-gp75]> ~/src/mylinux/scripts/cassandraSstableCopy.sh . /tmp/toto
# Copying all sstables from the source directory including sub-directories
#
# sstablecopyfile ./lb-1-big-Data.db /tmp/toto//.
# File with name lb-1-big-Data.db already exists, ID number will be incremented before copy
# comparing ./lb-1-big-Data.db /tmp/toto/./lb-1-big-Data.db
#   SKIP : similar file already exists in destination : cmp ./lb-1-big-Data.db /tmp/toto/./lb-1-big-Data.db
#
# sstablecopyfile ./lb-2-big-Data.db /tmp/toto//.
# File with name lb-2-big-Data.db already exists, ID number will be incremented before copy
# comparing ./lb-2-big-Data.db /tmp/toto/./lb-1-big-Data.db
# comparing ./lb-2-big-Data.db /tmp/toto/./lb-2-big-Data.db
#   SKIP : similar file already exists in destination : cmp ./lb-2-big-Data.db /tmp/toto/./lb-2-big-Data.db


if [[ -z $(which stat 2>/dev/null) ]] ; then
    echo "tools not found : stat"
    exit 9
fi
if [[ -z $(which cmp 2>/dev/null) ]] ; then
    echo "tools not found : cmp"
    exit 9
fi

if [[ $# -ne 2 ]]; then
    echo "ERROR ! need 2 args"
    exit 9
fi

zsrc=$1
zdest=$2

if [[ ! -e ${zsrc} ]]; then
    echo "ERROR ! source not found ${zsrc} !"
    exit 9
elif [[ ! -d ${zdest} || -z ${zdest} ]]; then
    echo "ERROR ! Directory given in input not found : ${zdest} !"
    exit 9
fi


unalias sstablecopyfile 2>/dev/null
sstablecopyfile()
{
    src=$1
    dest=$2

    # option to enable many-to-many comparison of *-Data.db files to avoid duplicates even with name mismatch
    # this is time consuming
    comparecontent=1

    if [[ ! -e ${src} ]]; then
        echo "ERROR ! File not found ${src} !"
        exit 9
    elif [[ -d ${src} ]]; then
        echo "ERROR ! Directory given in input instead of a file :  ${src} !"
        exit 9
    elif [[ ! -d ${dest} || -z ${dest} ]]; then
        echo "ERROR ! Directory given in input not found :  ${dest} !"
        exit 9
    else
        srcfile=`basename ${src}`
        srcdir=`dirname ${src}`
        suffix=`echo ${srcfile} | awk -F "-" '{ print $NF}'`
        prefix=${srcfile%%$suffix}
        filelist=`ls $(dirname ${src})/${prefix}*`
        toberenamed=0
        if [[ ! -z `ls ${dest}/${prefix}* 2>/dev/null` ]] ; then
            echo "  File with name ${srcfile} already exists, ID number will be incremented before copy"
            toberenamed=1
        fi
        if [[ ${toberenamed} -eq 0 ]]; then
            for filewithpath in ${filelist} ; do
                echo "cp -a -i ${filewithpath} ${dest}/"
                cp -a -i ${filewithpath} ${dest}/
                if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
            done
        else
            matching="0"
            if [[ ${comparecontent} -eq 1 ]] ; then
                srcData=${prefix}Data.db
                srcSize=$(stat -c%s ${srcdir}/${srcData})
                if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
                for cmpfile in `\ls ${dest}/*-Data.db`; do
                    echo "  comparing ${srcdir}/${srcData} ${cmpfile}"
                    if [[ `stat -c%s ${cmpfile}` -eq ${srcSize} ]]; then
                        cmp ${srcdir}/${srcData} ${cmpfile}
                        if [[ $? -eq 0 ]]; then
                            matching=${cmpfile}
                            break
                        fi
                    fi
                done
            fi
            if [[ ${matching} = "0" ]]; then
                lastnumber=`ls ${srcdir}/*.db ${dest}/*.db | awk -F "-" '{ print $2 }' | sort -n |tail -1`
                if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
                newnumber=$((${lastnumber}+1))
                for filewithpath in ${filelist} ; do
                    f=`basename ${filewithpath}`
                    if [[ `echo ${f} | grep -o "-" | wc -l` -ne 3 ]] ; then
                        echo "Error naming not supported : $f \n should be like lb-3-big-Data.db"
                        exit 9
                    else
                        pre=`echo ${f} | awk -F "-" '{ print $1}'`
                        suf=`echo ${f} | awk -F "-" '{ print $3}'`
                        echo "cp -a -i ${filewithpath} ${dest}/${pre}-${newnumber}-${suf}-`echo ${f} | awk -F "-" '{ print $NF}'`"
                        cp -a -i ${filewithpath} ${dest}/${pre}-${newnumber}-${suf}-`echo ${f} | awk -F "-" '{ print $NF}'`
                        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
                    fi
                done
            else
                echo "  SKIP : similar file already exists in destination : cmp $srcdir/$srcData $matching"
            fi
        fi
    fi
}

if [[ -d ${zsrc} ]]; then
    echo "Copying all sstables from the source directory including sub-directories"
    echo ""
    cwd=$(pwd)
    cd $zsrc
    list=`find . -type f -name "*-Data.db" 2>/dev/null`
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
    for f in $list ; do 
        zdir=`dirname ${f}`
        if [[ ! -d ${zdest}/${zdir} ]]; then
            echo "mkdir -p ${zdest}/${zdir}"
            mkdir -p ${zdest}/${zdir}
            if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $?" ; exit 1 ; fi
        fi
        echo "sstablecopyfile $f $zdest//${zdir}"
        sstablecopyfile $f ${zdest}/${zdir}
        echo ""
    done
    cd $cwd
else
    sstablecopyfile $zsrc $zdest
fi
