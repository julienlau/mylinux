#!/bin/bash

KUBE_NS=default
apiserver=https://kubernetes.default.svc
#k8s://kubernetes.default.svc.cluster.local:443
apiserver=$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")
sa=spark-sa

usage () {
    echo "Usage: $0 [-n spark-ns]"
    echo "Examples:"
    echo " $0 -n spark # to run in a specific namespace"
    echo " $0 -s spark-sa # to run with a specific serviceaccount"
    echo "";
}

while getopts "n:s:h" ARGOPTS ; do
    case ${ARGOPTS} in
        n) KUBE_NS=$OPTARG
            ;;
        s) sa=$OPTARG
            ;;
        h) usage; exit;
            ;;
        ?) usage; exit;
            ;;
    esac
done

#  --conf spark.kubernetes.container.image=pepitedata/spark-hadoop:3.4.1-3.3.6 \
#  --conf spark.kubernetes.container.image.pullSecrets=myicr \
#  --num-executors 2 \
set -x
name=python-pi
echo "spark-submit $name"
time spark-shell --master k8s://${apiserver} \
  --name $name \
  --deploy-mode cluster \
  --executor-cores 1 \
  --executor-memory 1g \
  --conf spark.ui.enabled=false \
  --conf spark.dynamicAllocation.enabled=true \
  --conf spark.dynamicAllocation.initialExecutors=1 \
  --conf spark.dynamicAllocation.executorIdleTimeout=20s \
  --conf spark.kubernetes.namespace=${KUBE_NS} \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=${sa} \
  --conf spark.kubernetes.container.image=pepitedata/spark-hadoop:debug \
  --class org.apache.spark.examples.SparkPi \
  local:///opt/spark/examples/src/main/python/pi.py \
  1 > /tmp/spark-submit-$name.log
if [[ $(kubectl logs -n ${KUBE_NS} -lspark-app-name=$name --tail 1000 | grep -c "Pi is roughly") -ne 1 ]]; then echo "ERROR $name"; exit 99; fi

# spark-submit --class org.apache.spark.repl.Main local:///opt/spark/jars/spark-repl_2.12-3.4.1.jar
# spark-submit --class org.apache.spark.repl.Main
