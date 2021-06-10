#!/bin/sh

usage()
{
    echo "Usage:"
    echo "      $(basename $0) <mesos-dispatcher> <mesos-role> <docker-images> <jar> <class-to-exec>"
    echo ""
    echo "	Example: $(basename $0) mesos://leader.mesos/service/spark spark-role mesosphere/spark:1.0.1-1.6.1-2 http://172.31.3.56/spark-examples-1.6.1.jar org.apache.spark.examples.SparkPi"
}

launch()
{
    docker run -e SPARK_JAVA_OPTS="-Dspark.mesos.executor.docker.image=$3 -Dspark.mesos.role=$2" $3 bin/spark-submit --deploy-mode cluster --master $1 --conf spark.mesos.role=$2 --conf spark.mesos.executor.docker.image=$3 --class $5 $4
}

cd $PWD
case $# in
    5) launch $1 $2 $3 $4 $5;;
    *) usage; exit 0;;
esac

