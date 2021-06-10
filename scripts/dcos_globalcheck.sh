#!/bin/bash
. /etc/profile 

tab=`echo -e "\t"`
find /var/lib/mesos/slave \( -name stderr -print  -o -name stdout -print \) -mtime -1 2>/dev/null | xargs grep -e '^ERROR' -e "^java.lang." -e " ERROR " -e "^java.io" -e "Exception" -e "^$tab\at " -e 'error' -e "\[ERROR\]"
