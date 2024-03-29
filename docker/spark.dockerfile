# docker build --progress=plain -t pepitedata/spark:3.5.0 -f spark.dockerfile .

#######################
FROM eclipse-temurin:11-jdk-focal as base

ARG spark_uid=10000
ARG spark_gid=10000
RUN groupadd -g ${spark_gid} spark && useradd spark -u ${spark_uid} -g ${spark_gid} -m -s /bin/bash

ENV SPARK_HOME=/opt/spark

RUN dpkg --configure -a && \
    apt-get install -fy --no-install-recommends && \
    apt-get autoclean && \
    apt-get autoremove --purge -y && \
    apt-get update -y --fix-missing --no-install-recommends && \
    set -ex && \
    ln -s /lib /lib64 && \
    apt-get install -y --no-install-recommends --allow-downgrades bash tini libc6 libpam-modules krb5-user libnss3 procps curl unzip gzip && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    apt autoclean -y

#######################
# SPARK
ENV SPARK_VERSION=3.5.0
ENV SPARK_MINOR=3.5
ENV SCALA_VERSION=2.12
#----------------------- version to adjust
ENV SPARK_PACKAGE=spark-${SPARK_VERSION}-bin-hadoop3
ENV SPARK_HOME=/opt/spark
RUN curl -sL --retry 3 \
    https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz | gunzip | tar x -C /opt/ && \
    mv /opt/${SPARK_PACKAGE} ${SPARK_HOME} && \
    mkdir -p ${SPARK_HOME}/examples && \
    curl -sL --retry 3 https://repo1.maven.org/maven2/org/apache/spark/spark-hadoop-cloud_${SCALA_VERSION}/${SPARK_VERSION}/spark-hadoop-cloud_${SCALA_VERSION}-${SPARK_VERSION}.jar -o ${SPARK_HOME}/jars/spark-hadoop-cloud_${SCALA_VERSION}-${SPARK_VERSION}.jar && \
    touch ${SPARK_HOME}/RELEASE && \
    chown -R spark:spark ${SPARK_HOME} && \
    chmod -R go+rX ${SPARK_HOME}
ENV PATH=$PATH:${SPARK_HOME}/bin

RUN echo "tuning ${SPARK_HOME}/conf/spark-defaults.conf" && \
echo "spark.serializer org.apache.spark.serializer.KryoSerializer" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.kubernetes.file.upload.path /tmp" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.path.style.access true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.magic.enabled true" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.name directory" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.establish.timeout 5000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.ssl.enabled false" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.connection.timeout 200000" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.fast.upload.buffer disk" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.multipart.size 512M" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.multipart.threshold 512M" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.threads.max 2048" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.buffer.dir /tmp/s3a" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.fs.s3a.committer.staging.tmp.path /tmp/staging" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.sql.parquet.output.committer.class org.apache.spark.internal.io.cloud.BindingParquetOutputCommitter" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.sql.sources.commitProtocolClass org.apache.spark.internal.io.cloud.PathOutputCommitProtocol" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
echo "spark.hadoop.mapreduce.outputcommitter.factory.scheme.s3a org.apache.hadoop.fs.s3a.commit.S3ACommitterFactory" >> ${SPARK_HOME}/conf/spark-defaults.conf
# echo "spark.hadoop.fs.s3a.buffer.dir ${hadoop.tmp.dir}/s3a" >> ${SPARK_HOME}/conf/spark-defaults.conf && \
# echo "#spark.hadoop.fs.s3a.impl org.apache.hadoop.spark.hadoop.fs.s3a.S3AFileSystem" >> ${SPARK_HOME}/conf/spark-defaults.conf

ENV SPARK_PRINT_LAUNCH_COMMAND=1
WORKDIR ${SPARK_HOME}
RUN cp kubernetes/dockerfiles/spark/entrypoint.sh /opt/. &&\
    cp kubernetes/dockerfiles/spark/decom.sh /opt/.
RUN echo "networkaddress.cache.ttl=30" >> ${JAVA_HOME}/conf/security/java.security

#######################
# OPTIONAL : python
ENV PYV=3.9
ENV PYTHONHASHSEED=0
ENV PYTHONIOENCODING=UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

RUN set -ex && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends --allow-downgrades -y python$PYV atop nmon vim && \
    apt autoclean -y &&\
    ln -s /usr/bin/python$PYV /usr/bin/python3 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    ls -la /usr/bin/python* && \
    python --version &&\
    python3 --version &&\
    readlink -f /usr/bin/python*

#######################
# OPTIONAL : additional jars
ENV ICEBERG_VERSION=1.4.2
ENV NESSIE_VERSION=0.73.0
ENV AWS_VERSION=1.12.589
WORKDIR ${SPARK_HOME}/examples/jars
RUN curl -sL --retry 3 https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-${SPARK_MINOR}_${SCALA_VERSION}/${ICEBERG_VERSION}/iceberg-spark-runtime-${SPARK_MINOR}_${SCALA_VERSION}-${ICEBERG_VERSION}.jar -o ${SPARK_HOME}/jars/iceberg-spark-runtime-${SPARK_MINOR}_${SCALA_VERSION}-${ICEBERG_VERSION}.jar && \
    curl -sL --retry 3 https://repo1.maven.org/maven2/org/projectnessie/nessie-integrations/nessie-spark-extensions-${SPARK_MINOR}_${SCALA_VERSION}/${NESSIE_VERSION}/nessie-spark-extensions-${SPARK_MINOR}_${SCALA_VERSION}-${NESSIE_VERSION}.jar -o ${SPARK_HOME}/jars/nessie-spark-extensions-${SPARK_MINOR}_${SCALA_VERSION}-${NESSIE_VERSION}.jar

RUN echo "jar spark-hadoop-cloud" &&\ 
    curl -sL --retry 3 -L "https://repo1.maven.org/maven2/org/apache/spark/spark-hadoop-cloud_${SCALA_VERSION}/${SPARK_VERSION}/spark-hadoop-cloud_${SCALA_VERSION}-${SPARK_VERSION}.jar" -o ${SPARK_HOME}/jars/spark-hadoop-cloud_${SCALA_VERSION}-${SPARK_VERSION}.jar

RUN echo "jar hadoop-aws" &&\
    curl -sL --retry 3 -L "https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/${HADOOP_VERSION}/hadoop-aws-${HADOOP_VERSION}.jar" -o ${SPARK_HOME}/jars/hadoop-aws-${HADOOP_VERSION}.jar

RUN echo "jar aws-java-sdk-bundle" &&\
    curl -sL --retry 3 -L "https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/${AWS_VERSION}/aws-java-sdk-bundle-${AWS_VERSION}.jar" -o ${SPARK_HOME}/jars/aws-java-sdk-bundle-${AWS_VERSION}.jar

#######################
# OPTIONAL : example jars
WORKDIR ${SPARK_HOME}/examples/jars
RUN curl -sL --retry 3 \
  https://github.com/julienlau/tpcx-hs/releases/download/v2.2.0/v2.2.0.tgz \
  | gunzip \
  | tar x -C ${SPARK_HOME}/examples/jars --strip-components=3 --wildcards --no-anchored '*TPCx-HS-master_Spark*.jar'
RUN curl -sL --retry 3 \
    https://github.com/julienlau/spark-data-generator/releases/download/1.0/parquet-data-generator_${SCALA_VERSION}-3.3.0_1.0.jar -o ./parquet-data-generator_${SCALA_VERSION}-3.3.0_1.0.jar
########

#######################
# Clean package
RUN apt remove -y unzip dnsutils fio gawk inetutils-traceroute ioping iperf iptraf iputils-tracepath iputils-ping lsof netcat nethogs net-tools nmap qperf rclone strace sudo sysbench sysstat && \
    apt autoremove -y &&\
    apt autoclean -y &&\
    rm -rf /var/cache/apt/*
########

#######################
# OPTIONAL : debug only
# RUN apt-get update && \
#     apt-get install -y --no-install-recommends --allow-downgrades -y atop bash binutils curl dnsutils dstat fio gawk htop iftop inetutils-traceroute ioping iotop iperf iptraf iputils-tracepath iputils-ping lsof netcat nethogs net-tools nmap nmon openssl qperf rclone strace sudo sysbench sysstat vim && \
#     rm -rf /var/cache/apt/* && \
#     curl -LO "https://dl.k8s.io/release/v1.24.13/bin/linux/amd64/kubectl" && \
#     mv ./kubectl /usr/local/bin/kubectl && \
#     chmod ugo+rx /usr/local/bin/kubectl
# RUN usermod -aG sudo spark && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# COPY spark-repl_2.12-3.4.1.jar ${SPARK_HOME}/jars/.
########

# this script should be launched after having copied your ssl certs in /usr/local/share/ca-certificates/
#COPY spark-env-ssl.sh /opt/.
RUN   mkdir -p /tmp/spark-events /tmp/staging /tmp/s3a ${SPARK_HOME}/workdir && \
      chmod -R go+rwX /tmp && \
      chmod -R go+rX /opt /home && \
      chmod g+wX ${SPARK_HOME}/workdir && \
      chmod a+x /opt/decom.sh && \
      chown -R spark:spark ${SPARK_HOME} && \
      chmod -R go+rX ${SPARK_HOME}

WORKDIR ${SPARK_HOME}/workdir

ENTRYPOINT [ "/opt/entrypoint.sh" ]

# Specify the User that the actual main process will run as
USER ${spark_uid}
SHELL ["/bin/bash", "-c"]
