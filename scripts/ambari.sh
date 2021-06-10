#!/bin/bash

USER='admin'
PASS='admin'
CLUSTER='main'
HOST=$(hostname -f):8080

function start(){
  curl -u $USER:$PASS -i -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Start '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function startWait(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Start '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
  wait $1 "STARTED"
}

function stop(){
  curl -u $USER:$PASS -i -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Stop '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function stopWait(){
  curl -s -u $USER:$PASS -H 'X-Requested-By: ambari' -X PUT -d \
    '{"RequestInfo": {"context" :"Stop '"$1"' via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' \
    http://$HOST/api/v1/clusters/$CLUSTER/services/$1
  wait $1 "INSTALLED"
}

function maintOff(){
  curl -u $USER:$PASS -i -H 'X-Requested-By: ambari' -X PUT -d \
  '{"RequestInfo":{"context":"Turn Off Maintenance Mode"},"Body":{"ServiceInfo":{"maintenance_state":"OFF"}}}' \
  http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function maintOn(){
  curl -u $USER:$PASS -i -H 'X-Requested-By: ambari' -X PUT -d \
  '{"RequestInfo":{"context":"Turn Off Maintenance Mode"},"Body":{"ServiceInfo":{"maintenance_state":"ON"}}}' \
  http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function delete(){
  curl -u $USER:$PASS -i -H 'X-Requested-By: ambari' -X DELETE http://$HOST/api/v1/clusters/$CLUSTER/services/$1
}

function wait(){
  finished=0
  while [ $finished -ne 1 ]
  do
    str=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/services/$1)
    if [[ $str == *"$2"* ]] || [[ $str == *"Service not found"* ]] 
    then
      finished=1
    fi
    sleep 3
  done
}

function check() {
  str=$(curl -s -u $USER:$PASS http://{$HOST}/api/v1/clusters/$CLUSTER/services/$1)
  if [[ $str == *"$2"* ]]
  then
    echo 1
  else
    echo 0
  fi
}

#start HDFS
#start YARN
#start HIVE
#start HBASE
#start GANGLIA
#start NAGIOS
#start ZOOKEEPER
#start STORM
#stop STORM
#stop HBASE
