#!/bin/bash

set -o allexport

alias sparkclean="kubectl get pods -n \${KUBE_NS} -lspark-role=driver --field-selector=status.phase!=Running | awk '{print \$1}' | grep -v '^NAME$' | xargs kubectl delete pods -n \${KUBE_NS}"
alias sclean="kubectl get sparkapp -n \${KUBE_NS} | grep -e ' COMPLETED ' -e ' FAILED ' | awk '{print \$1}' | grep -v '^NAME$' | xargs kubectl delete sparkapp -n \${KUBE_NS}"

spark-test-operator () {
    local f=$1 # spark-pi.yaml
    local timeout=$2 # integer value in seconds
    local opt=""
    if [[ $# -ge 3 ]]; then
        local ns=$3 #namespace
        opt="-n $ns"
    fi
    timeout=${timeout%%s}
    name=$(cat $f | yq .metadata.name)
    if [[ $(kubectl get sparkapp $opt 2>&1 | { grep -sc "^$name " || test $? = 1; }) -gt 0 ]]; then
        echo "Delete previous run of sparkapp $name in NS $ns"
        kubectl delete sparkapp $opt ${name} 2>/dev/null 1>/dev/null
    fi
    kubectl apply $opt -f ${f}
    if [[ $? -ne 0 ]] ; then echo "ERROR running test $f"; fi
    c=0
    while [[ $c -lt $timeout ]]; do
        status=$(kubectl get $opt sparkapp $name --no-headers | awk '{print $2}')
        if [[ "${status}" == "COMPLETED" ]]; then
            c=$timeout
        fi
        sleep 10
        c=$(($c+10))
    done
    status=$(kubectl get $opt sparkapp $name --no-headers | awk '{print $2}')
    if [[ "${status}" != "COMPLETED" ]] ; then echo "ERROR running test $f"; exit 99; fi
    kubectl get sparkapp $opt $name
}

spark-test-operator-wait () {
    local f=$1 # spark-pi.yaml
    local timeout=$2 # 3m
    local opt=""
    if [[ $# -ge 3 ]]; then
        local ns=$3 #namespace
        opt="-n $ns"
    fi
    name=$(cat $f | yq .metadata.name)
    if [[ $(kubectl get sparkapp $opt 2>&1 | { grep -sc "^$name " || test $? = 1; }) -gt 0 ]]; then
        echo "Delete previous run of sparkapp $name in NS $ns"
        kubectl delete sparkapp $opt ${name} 2>/dev/null 1>/dev/null
    fi
    kubectl apply $opt -f ${f}
    if [[ $? -ne 0 ]] ; then echo "ERROR running test $f"; fi
    sleep 5
    kubectl wait $opt --for=jsonpath='{.status.applicationState.state}'=COMPLETED sparkapp/${name} --timeout=$timeout
    if [[ $? -ne 0 ]] ; then echo "ERROR running test $f"; exit 99; fi
    kubectl get sparkapp $opt $name 
}

setspark() {
if [[ -z ${SPARK_EXECUTOR_MEMORY} ]]; then
    echo "You must set env variables !!!"
    echo "examples:"
    echo "export SPARK_DRIVER_MEMORY=1g
export SPARK_EXECUTOR_MEMORY=2g
export SPARK_EXECUTOR_CORES=2
export SPARK_EXECUTOR_INSTANCES=2
export SPARK_MASTER_URL=k8s://$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")
export KUBE_NS=spark
export SPARK_KUBE_SA=spark-sa
export SPARK_KUBE_IMAGE=pepitedata/spark:3.5.0
export SPARK_KUBE_IMAGE_PULLSECRETS=my-icr
export s3address="'$(vault kv get -field=address secret/minio/api-key)'"
export AWS_ACCESS_KEY_ID="'$(vault kv get -field=access-key secret/minio/api-key)'"
export AWS_SECRET_ACCESS_KEY="'$(vault kv get -field=secret-key secret/minio/api-key)'
else
    export sparkopt="--deploy-mode cluster"
    local conf=./spark-defaults.conf
    echo "spark.serializer=org.apache.spark.serializer.KryoSerializer" > $conf
    echo "spark.ui.enabled=true" >> $conf
    echo "spark.ui.prometheus.enabled=true" >> $conf
    echo "spark.executor.memory=${SPARK_EXECUTOR_MEMORY}" >> $conf
    if [[ ! -z ${SPARK_EXECUTOR_CORES} ]]; then
        echo "spark.executor.cores=${SPARK_EXECUTOR_CORES}" >> $conf
    fi
    if [[ ! -z ${SPARK_EXECUTOR_INSTANCES} ]]; then
        echo "spark.executor.instances=${SPARK_EXECUTOR_INSTANCES}" >> $conf
    fi
    if [[ ! -z ${SPARK_MASTER_URL} ]]; then
        echo "spark.master=${SPARK_MASTER_URL}" >> $conf
    fi
    if [[ ! -z ${SPARK_KUBE_IMAGE} ]]; then
        echo "spark.kubernetes.container.image=${SPARK_KUBE_IMAGE}" >> $conf
        echo "spark.kubernetes.container.image.pullPolicy=Always" >> $conf
    fi
    if [[ ! -z ${SPARK_DRIVER_MEMORY} ]]; then
        echo "spark.driver.memory=${SPARK_DRIVER_MEMORY}" >> $conf
    fi
    if [[ ! -z ${SPARK_DRIVER_CORES} ]]; then
        echo "spark.driver.cores=${SPARK_DRIVER_CORES}" >> $conf
    fi
    if [[ ! -z ${KUBE_NS} ]]; then
        echo "spark.kubernetes.namespace=${KUBE_NS}" >> $conf
    fi
    if [[ ! -z ${SPARK_KUBE_SA} ]]; then
        echo "spark.kubernetes.authenticate.driver.serviceAccountName=${SPARK_KUBE_SA}" >> $conf
    fi
    if [[ ! -z ${SPARK_KUBE_IMAGE_PULLSECRETS} ]]; then
        echo "spark.kubernetes.container.image.pullSecrets=${SPARK_KUBE_IMAGE_PULLSECRETS}" >> $conf
    fi
    if [[ ! -z ${SPARK_DEFAULT_PARALLELISM} ]]; then
        export sparkopt="$sparkopt --conf spark.default.parallelism=${SPARK_DEFAULT_PARALLELISM}"
    fi
    if [[ ! -z ${s3address} ]]; then
        if [[ -z $AWS_ACCESS_KEY_ID || -z $AWS_SECRET_ACCESS_KEY ]]; then
            echo "ERROR !"
            echo "ERROR ! empty var for s3"
            echo "ERROR !"
        fi
        if [[ -z ${SPARK_DEFAULTFS} ]]; then
            export SPARK_DEFAULTFS=s3a://$s3address
        fi
        echo "spark.hadoop.fs.defaultFS=$SPARK_DEFAULTFS" >> $conf
        echo "spark.hadoop.fs.s3a.endpoint=https://$s3address" >> $conf
        echo "spark.hadoop.fs.s3a.connection.ssl.enabled=true" >> $conf
        echo "spark.hadoop.fs.s3a.path.style.access=true" >> $conf
        echo "spark.hadoop.fs.s3a.committer.name=magic" >> $conf
        echo "spark.hadoop.fs.s3a.directory.marker.retention=keep" >> $conf
        echo "spark.hadoop.fs.s3a.bucket.all.committer.magic.enabled=true" >> $conf
        echo "spark.sql.sources.commitProtocolClass=org.apache.spark.internal.io.cloud.PathOutputCommitProtocol" >> $conf
        echo "spark.sql.parquet.output.committer.class=org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter" >> $conf
        # echo "spark.hadoop.fs.s3a.threads.max=128" >> $conf
        # echo "spark.hadoop.fs.s3a.connection.maximum=128" >> $conf
        # echo "spark.hadoop.fs.s3a.max.total.tasks=2048" >> $conf
        # echo "spark.hadoop.fs.s3a.fast.upload.active.blocks=20" >> $conf
        # echo "spark.hadoop.fs.s3a.block.size=128M" >> $conf
        echo "spark.hadoop.fs.s3a.fast.upload.buffer=bytebuffer" >> $conf

        export sparkopt=$sparkopt' --conf "spark.driver.extraJavaOptions=-Dcom.amazonaws.services.s3.enableV4=true" --conf "spark.executor.extraJavaOptions=-Dcom.amazonaws.services.s3.enableV4=true"'
        export sparkopt="$sparkopt --conf spark.hadoop.fs.s3a.access.key=$AWS_ACCESS_KEY_ID --conf spark.hadoop.fs.s3a.secret.key=$AWS_SECRET_ACCESS_KEY"
    fi
    echo "spark.hadoop.mapreduce.fileoutputcommitter.cleanup-failures.ignored=true" >> $conf
    echo "spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version=2" >> $conf
    echo "spark.hadoop.mapreduce.fileoutputcommitter.marksuccessfuljobs=true" >> $conf

    echo "spark.authenticate=true" >> $conf
    echo "spark.network.crypto.enabled=true" >> $conf
    echo "spark.network.crypto.keyLength=256" >> $conf
    echo "spark.network.crypto.saslFallback=false" >> $conf
    # aeskey=`echo "spark-$(uuidgen)" | sha256sum | awk '{print $1}'`
    # export sparkopt="$sparkopt --conf spark.authenticate.secret=${aeskey}"
    # echo "spark.authenticate.secret.file=/etc/secret-spark-aes" >> $conf
    # echo "spark.kubernetes.driver.secrets.spark-aes=/etc/secret-spark-aes" >> $conf
    # echo "spark.kubernetes.executor.secrets.spark-aes=/etc/secret-spark-aes" >> $conf
    echo "" >> $conf

    if [[ ! -z ${SPARK_EVENT_LOGDIR} ]]; then
        echo "spark.eventLog.enabled=true" >> $conf
        echo "spark.eventLog.rolling.enabled=true" >> $conf
        echo "spark.eventLog.rolling.maxFileSize=512m" >> $conf
        if [[ `echo ${SPARK_EVENT_LOGDIR} | grep -c -e "^pvc" -e "pvc$"` -gt 0 ]]; then
            echo "spark.kubernetes.driver.volumes.persistentVolumeClaim.log-vol.mount.path=/tmp" >> $conf
            echo "spark.kubernetes.driver.volumes.persistentVolumeClaim.log-vol.mount.readOnly=false" >> $conf
            echo "spark.kubernetes.driver.volumes.persistentVolumeClaim.log-vol.options.claimName=${SPARK_EVENT_LOGDIR}" >> $conf
        else
            echo "spark.eventLog.dir=${SPARK_EVENT_LOGDIR}" >> $conf
        fi
    fi
fi

echo "You should submit your job using :"
echo "\$zsh> spark-submit --properties-file=$conf "'$=sparkopt --name spark-pi --class org.apache.spark.examples.SparkPi local:///opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar 10'
echo "\$bash> spark-submit --properties-file=$conf "'$sparkopt --name spark-pi --class org.apache.spark.examples.SparkPi local:///opt/spark/examples/jars/spark-examples_2.12-3.5.0.jar 10'
}
