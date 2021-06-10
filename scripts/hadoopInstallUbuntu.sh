#!/bin/bash
. /etc/profile

# this script ease installation of a 5 nodes cluster

addgroup hdfs
adduser -ingroup hdfs hdfs yarn
wget http://apache.crihan.fr/dist/hadoop/common/hadoop-2.8.1/hadoop-2.8.1.tar.gz
ln -s hadoop-2.8.1 hadoop
mkdir -p /home/hdfs/.ssh /home/yarn/.ssh
cat /home/coretech/.ssh/coretech.pem > /home/hdfs/.ssh/coretech.pem
cat /home/coretech/.ssh/coretech.pem > /home/yarn/.ssh/coretech.pem
chown -R hdfs /home/hdfs/.ssh
chown -R yarn /home/yarn/.ssh
chmod go-rwx /home/hdfs/.ssh/*.* /home/yarn/.ssh/*.*

echo "export HADOOP_HOME=/opt/hadoop" >> /etc/profile 
echo "export PATH=$PATH:/opt/hadoop/bin:/opt/hadoop/sbin" >> /etc/profile 

mkdir -p /dcos/volume1/hadoop/logs /dcos/volume2/hadoop/tmp /dcos/volume0/hdfs/namenode /dcos/volume0/hdfs/namesecondary /dcos/volume0/hdfs/datanode
chown -R hdfs:hdfs /opt/hadoop* /dcos/volume1/hadoop/logs /dcos/volume2/hadoop/tmp /dcos/volume0/hdfs/namenode /dcos/volume0/hdfs/namesecondary /dcos/volume0/hdfs/datanode
# OR 
mkdir -p /hadoop/logs /hadoop/tmp /hadoop/hdfs/namenode /hadoop/hdfs/datanode
chown -R hdfs:hdfs /opt/hadoo* /hadoop/logs /hadoop/tmp /hadoop/hdfs/namenode /hadoop/hdfs/datanode

chmod -R g+w /opt/hadoo* /hadoop/logs /hadoop/tmp /hadoop/hdfs/namenode /hadoop/hdfs/datanode /dcos/volume1/hadoop/logs /dcos/volume2/hadoop/tmp /dcos/volume0/hdfs/namenode /dcos/volume0/hdfs/namesecondary /dcos/volume0/hdfs/datanode

# emacs /opt/hadoop/etc/hadoop/hadoop-env.sh
# emacs /opt/hadoop/etc/hadoop/mapred-site.xml
# emacs /opt/hadoop/etc/hadoop/hdfs-site.xml
# emacs /opt/hadoop/etc/hadoop/yarn-site.xml
# emacs /opt/hadoop/etc/hadoop/slave
