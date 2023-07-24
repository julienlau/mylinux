# docker build --progress=plain -t pepitedata/spark-hadoop:3.4.1-3.3.6 -f spark.dockerfile .
FROM eclipse-temurin:11-jdk-focal

ARG spark_uid=10000
RUN groupadd -g 10001 spark && useradd spark -u 10000 -g 10001 -m -s /bin/bash

ENV SPARK_HOME /opt/spark

RUN dpkg --configure -a && \
    apt-get install -fy --no-install-recommends && \
    apt-get autoclean && \
    apt-get autoremove --purge -y && \
    apt-get update -y --fix-missing --no-install-recommends && \
    set -ex && \
    ln -s /lib /lib64 && \
    apt-get install -y --no-install-recommends --allow-downgrades bash tini libc6 libpam-modules krb5-user libnss3 procps && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

#######################
# HADOOP
ENV HADOOP_VERSION 3.3.6
#----------------------- version to adjust
ENV HADOOP_HOME /opt/hadoop
RUN curl -sL --retry 3 \
  "http://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz" \
  | gunzip \
  | tar -x -C /opt/ \
 && mv /opt/hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
 && rm -rf ${HADOOP_HOME}/share/doc ${HADOOP_HOME}/share/hadoop/yarn \
 && chown -R spark:spark ${HADOOP_HOME} \
 && chmod -R go+rX ${HADOOP_HOME}

ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV PATH $PATH:${HADOOP_HOME}/bin
ENV HADOOP_YARN_HOME ${HADOOP_HOME}
ENV HADOOP_MAPRED_HOME ${HADOOP_HOME}
ENV HADOOP_OPTIONAL_TOOLS "hadoop-aws"

#######################
# SPARK
ENV SPARK_VERSION 3.4.1
ENV SCALA_VER 2.12
#----------------------- version to adjust
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-without-hadoop
ENV SPARK_HOME /opt/spark
RUN curl -sL --retry 3 \
  https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz \
  | gunzip \
  | tar x -C /opt/ && \
 mv /opt/${SPARK_PACKAGE} ${SPARK_HOME} && \
 mkdir -p ${SPARK_HOME}/examples && \
  curl -sL --retry 3 \
    https://repo1.maven.org/maven2/org/apache/spark/spark-hadoop-cloud_${SCALA_VER}/${SPARK_VERSION}/spark-hadoop-cloud_${SCALA_VER}-${SPARK_VERSION}.jar -o ${SPARK_HOME}/jars/spark-hadoop-cloud_${SCALA_VER}-${SPARK_VERSION}.jar && \
 cp ${HADOOP_HOME}/etc/hadoop/hadoop-metrics2.properties ${SPARK_HOME}/conf/ && \
 touch ${SPARK_HOME}/RELEASE && \
 chown -R spark:spark ${SPARK_HOME} && \
 chmod -R go+rX ${SPARK_HOME}
ENV PATH $PATH:${SPARK_HOME}/bin
# entrypoint.sh will use env var to set properly the classpath : SPARK_HOME HADOOP_HOME HADOOP_CONF_DIR
# initial classpath given by: ${HADOOP_HOME}/bin/hadoop classpath
# hadoop classpath -> /opt/hadoop/etc/hadoop:/opt/hadoop/share/hadoop/common/lib/*:/opt/hadoop/share/hadoop/common/*:/opt/hadoop/share/hadoop/hdfs:/opt/hadoop/share/hadoop/hdfs/lib/*:/opt/hadoop/share/hadoop/hdfs/*
# should work but does not : ENV SPARK_EXTRA_CLASSPATH ${HADOOP_HOME}/share/hadoop/tools/lib/*
ENV SPARK_DIST_CLASSPATH ${HADOOP_HOME}/etc/hadoop:${HADOOP_HOME}/share/hadoop/common/lib/*:${HADOOP_HOME}/share/hadoop/common/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/hdfs/lib/*:${HADOOP_HOME}/share/hadoop/hdfs/*:${HADOOP_HOME}/share/hadoop/mapreduce/lib/*:${HADOOP_HOME}/share/hadoop/mapreduce/*:${HADOOP_HOME}/share/hadoop/tools/lib/*
ENV LD_LIBRARY_PATH $HADOOP_HOME/lib/native

RUN echo "tuning ${SPARK_HOME}/conf/spark-defaults.conf" && \
echo "spark.serializer org.apache.spark.serializer.KryoSerializer" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.path.style.access true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.block.size 512M" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.magic.enabled false" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.name directory" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.staging.abort.pending.uploads true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.staging.conflict-mode append" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.staging.unique-filenames true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.threads 2048 # number of threads writing to MinIO" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.establish.timeout 5000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.maximum 8192 # maximum number of concurrent conns" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.ssl.enabled false" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.timeout 200000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.fast.upload.active.blocks 2048 # number of parallel uploads" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.fast.upload.buffer disk # use disk as the buffer for uploads" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.fast.upload true # turn on fast upload mode" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.max.total.tasks 2048 # maximum number of parallel tasks" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.multipart.size 512M # size of each multipart chunk" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.multipart.threshold 512M # size before using multipart uploads" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.socket.recv.buffer 65536 # read socket buffer hint" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.socket.send.buffer 65536 # write socket buffer hint" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.threads.max 2048 # maximum number of threads for S3A" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.buffer.dir /tmp/s3a" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.staging.tmp.path /tmp/staging" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.sql.parquet.output.committer.class org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.sql.sources.commitProtocolClass org.apache.spark.internal.io.cloud.PathOutputCommitProtocol" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory" >> ${SPARK_HOME}/conf/spark-defaults.conf
# echo "spark.hadoop.fs.s3a.buffer.dir ${hadoop.tmp.dir}/s3a" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
# echo "#spark.hadoop.fs.s3a.impl org.apache.hadoop.spark.hadoop.fs.s3a.S3AFileSystem" >> ${SPARK_HOME}/conf/spark-defaults.conf

ENV SPARK_PRINT_LAUNCH_COMMAND 1
WORKDIR ${SPARK_HOME}
RUN cp kubernetes/dockerfiles/spark/entrypoint.sh /opt/. \
 && cp kubernetes/dockerfiles/spark/decom.sh /opt/.
RUN echo "networkaddress.cache.ttl=30" >> ${JAVA_HOME}/conf/security/java.security

#######################
# OPTIONAL : python
ENV PYV 3.9
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends --allow-downgrades -y python$PYV atop nmon net-tools curl vim && \
    rm -rf /var/cache/apt/*

RUN ln -s /usr/bin/python$PYV /usr/bin/python3 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    ls -la /usr/bin/python* && \
    readlink -f /usr/bin/python*

#######################
# OPTIONAL : debug only
RUN apt-get update && \
    apt-get install -y --no-install-recommends --allow-downgrades -y atop bash binutils curl dnsutils dstat fio gawk htop iftop inetutils-traceroute ioping iotop iperf iptraf iputils-tracepath iputils-ping libc6 lsof netcat nethogs net-tools nmap nmon openssl procps python3 qperf rclone strace sudo sysbench sysstat tini vim && \
    rm -rf /var/cache/apt/* && \
    curl -LO "https://dl.k8s.io/release/v1.24.13/bin/linux/amd64/kubectl" && \
    mv ./kubectl /usr/local/bin/kubectl && \
    chmod ugo+rx /usr/local/bin/kubectl
RUN usermod -aG sudo spark && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
########

#######################
# OPTIONAL : example jars
WORKDIR ${SPARK_HOME}/examples/jars
RUN curl -sL --retry 3 \
  https://github.com/julienlau/tpcx-hs/releases/download/v2.2.0/v2.2.0.tgz \
  | gunzip \
  | tar x -C ${SPARK_HOME}/examples/jars --strip-components=3 --wildcards --no-anchored '*TPCx-HS-master_Spark*.jar'
RUN curl -sL --retry 3 \
    https://github.com/julienlau/spark-data-generator/releases/download/1.0/parquet-data-generator_2.12-3.3.0_1.0.jar -o ./parquet-data-generator_2.12-3.3.0_1.0.jar
########

# this script should be launched after having copied your ssl certs in /usr/local/share/ca-certificates/
#COPY spark-env-ssl.sh /opt/.
RUN   mkdir -p /tmp/spark-events /tmp/staging /tmp/s3a ${SPARK_HOME}/workdir && \
      chmod -R go+rwX /tmp && \
      chmod g+wX ${SPARK_HOME}/workdir && \
      chmod a+x /opt/decom.sh && \
      chown -R spark:spark ${SPARK_HOME} && \
      chmod -R go+rX ${SPARK_HOME}

WORKDIR ${SPARK_HOME}/workdir

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
SHELL ["/bin/bash", "-c"]
