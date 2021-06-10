#!/bin/bash

clustername=lri-hdi-scus

if [[ $# -ge 1 ]]; then
    clustername=$1
fi
if [[ $# -ge 2 ]]; then
    password=$2
fi

#get list of host in string separate by espace
buffer=`curl -u admin:$password -G "https://$clustername.azurehdinsight.net/api/v1/clusters/$clustername/hosts" | jq '.items[].Hosts.host_name'`

#create an array with all hosts
SEP=' ' read -r -a names <<< $buffer

#hostfile=/etc/ansible/hosts
hostfile=hosts

echo "" >> $hostfile

echo "#[$clustername]" >> $hostfile
tab=`echo -e "\t"`

for name in ${names[@]}
{
    #remove double quote
    name="${name%\"}"
    name="${name#\"}"

    #get the ip with the host name
    ip=$(ping -c 1 $name | awk -F'[()]' '/PING/{print $2}')

    type=${name:0:2}

    if [ $type != 'zk' ] 
    then
	echo "$ip $tab $(echo $name | awk -F '.' '{print $1}') $tab $name" >> $hostfile
    else
	echo "$ip $tab $(echo $name | awk -F '.' '{print $1}') $tab $name" >> $hostfile
    fi
}
echo "" >> $hostfile

echo "File written : $hostfile"
