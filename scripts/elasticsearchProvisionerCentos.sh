#!/bin/bash
# https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-centos-7

install_pre_java()
{
    yum install -y epel-release unzip dstat ncdu htop curl jq nmap wget xeyes nano emacs vim jna ntp nfs-utils python-pip PyYAML py-dateutil numpy nano
}

install_post_java()
{
    yum install -y jna
    echo "* - memlock unlimited" >> /etc/security/limits.conf
    echo "* - nofile 131072" >> /etc/security/limits.conf
    echo "* - nproc 32768" >> sudo tee -a /etc/security/limits.conf
    echo "* - as unlimited" >> sudo tee -a  /etc/security/limits.conf
    # remove swap entierly
    swapoff --all
}

install_java_oracle()
{
    export kernelver=$(uname -s)$(uname -r)
    export linuxDistro=`lsb_release -i | awk -F ':' '{print $2}' | xargs echo`
    export linuxDistroVer=`lsb_release -d | awk -F ':' '{print $2}' | xargs echo`

    export simpleuser=$(ls -rt /home/ |tail -1 | awk -F '/' '{print $NF}')

    archTag=linux-x64.rpm
    if [[ $linuxDistro = "Ubuntu" || -z $(which rpm 2>/dev/null) ]]; then
        archTag=linux-x64.tar.gz
    fi

    \cd /tmp
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    urlOracle="http://www.oracle.com/"
    jdkurl=`curl -s ${urlOracle}/technetwork/java/javase/downloads/index.html | grep -Po "\/technetwork\/java/\javase\/downloads\/jdk[8-9]-downloads-.+?\.html" | tail -1`
    jdkurl="${urlOracle}${jdkurl}"
    jdkurl=`curl -s ${jdkurl} | grep   "http\:\/\/download.oracle\.com\/otn-pub\/java\/jdk\/[8-9]*" | grep $archTag |tail -1 | awk -F'"' '{ print $12}'`
    jdkarch=`echo ${jdkurl} | awk -F"/" '{print $NF}'`
    jdkarchNoSuffix=${jdkarch%%.rpm}
    jdkarchNoSuffix=${jdkarchNoSuffix%%.tar.gz}
    if [[ ! -e $jdkarch ]] ; then
        wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" ${jdkurl}
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi
    # example of verion : jdk-8u102-linux-x64.rpm jdk-8u92-linux-x64.rpm
    jdkver=`echo ${jdkarch} | awk -F"-" '{print $2}'`
    jdkpriority=910`echo ${jdkver} | awk -F"u" '{print $1}'`0`echo ${jdkver} | awk -F"u" '{print $2}' `
    jdkpriority=`echo $jdkpriority|  cut -c 1-7`
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

    if [[ -z ${JAVA_DIR} ]] ; then
        if [[ -d /usr/lib64/jvm ]]; then
            JAVA_DIR=/usr/lib64/jvm
        elif [[ -d /usr/lib/jvm ]]; then
            JAVA_DIR=/usr/lib/jvm
        else
            JAVA_DIR=/usr/java
        fi
    fi
    echo "JAVA_DIR=$JAVA_DIR"
    mkdir -p ${JAVA_DIR}
    if [[ $linuxDistro = "Ubuntu" || -z $(which rpm 2>/dev/null) ]]; then
        echo "fakeroot make-jpkg ${jdkarch}"
        sudo su - $simpleuser -c "cd /tmp; echo Y | fakeroot make-jpkg ${jdkarch}"
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
        jdkdeb=$(ls -rt oracle-java*.deb |tail -1 | awk '{print $NF}')
        mv jdkdeb
        \cd ${JAVA_DIR}
        echo "dpkg -i /tmp/$jdkdeb"
        dpkg -i /tmp/${jdkdeb}
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    else
        \cd ${JAVA_DIR}
        echo "rpm -ivh --prefix=${JAVA_DIR} /tmp/${jdkarch}"
        rpm -ivh --prefix=${JAVA_DIR} /tmp/${jdkarch}
        if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    fi
    \rm /tmp/${jdkarch}
    \cd ${JAVA_DIR}
    jdkinstalldir=`\ls -lrt | grep ^d | tail -1 | awk '{print $NF}'`
    jdkinstalldir=$(pwd)/${jdkinstalldir}
    echo "jdkinstalldir=$jdkinstalldir"
    echo "jdkpriority=$jdkpriority"

    update-alternatives --install /usr/bin/java java ${jdkinstalldir}/bin/java ${jdkpriority}    
    update-alternatives --install /usr/bin/java java ${jdkinstalldir}/bin/java ${jdkpriority}    --slave /usr/bin/java-rmi.cgi java-rmi.cgi  ${jdkinstalldir}/bin/java-rmi.cgi --slave /usr/bin/javafxpackager javafxpackager  ${jdkinstalldir}/bin/javafxpackager
    #--slave /usr/bin/idlj idlj ${jdkinstalldir}/bin/idlj
    #--slave /usr/bin/jvisualvm jvisualvm  ${jdkinstalldir}/bin/jvisualvm 
    #--slave /usr/bin/jcmd jcmd  ${jdkinstalldir}/bin/jcmd 

    update-alternatives --install /usr/bin/javac javac ${jdkinstalldir}/bin/javac ${jdkpriority}
    update-alternatives --install /usr/bin/javac javac ${jdkinstalldir}/bin/javac ${jdkpriority} --slave /usr/bin/jstatd jstatd  ${jdkinstalldir}/bin/jstatd --slave /usr/bin/jps jps  ${jdkinstalldir}/bin/jps --slave /usr/bin/rmic rmic  ${jdkinstalldir}/bin/rmic --slave /usr/bin/extcheck extcheck  ${jdkinstalldir}/bin/extcheck --slave /usr/bin/javadoc javadoc  ${jdkinstalldir}/bin/javadoc --slave /usr/bin/jconsole jconsole  ${jdkinstalldir}/bin/jconsole --slave /usr/bin/jrunscript jrunscript  ${jdkinstalldir}/bin/jrunscript --slave /usr/bin/jdb jdb  ${jdkinstalldir}/bin/jdb --slave /usr/bin/jsadebugd jsadebugd  ${jdkinstalldir}/bin/jsadebugd --slave /usr/bin/native2ascii native2ascii  ${jdkinstalldir}/bin/native2ascii --slave /usr/bin/wsgen wsgen  ${jdkinstalldir}/bin/wsgen --slave /usr/bin/jar jar  ${jdkinstalldir}/bin/jar --slave /usr/bin/javah javah  ${jdkinstalldir}/bin/javah --slave /usr/bin/jhat jhat  ${jdkinstalldir}/bin/jhat --slave /usr/bin/jstack jstack  ${jdkinstalldir}/bin/jstack --slave /usr/bin/schemagen schemagen  ${jdkinstalldir}/bin/schemagen --slave /usr/bin/wsimport wsimport  ${jdkinstalldir}/bin/wsimport --slave /usr/bin/jarsigner jarsigner  ${jdkinstalldir}/bin/jarsigner --slave /usr/bin/javap javap  ${jdkinstalldir}/bin/javap --slave /usr/bin/jinfo jinfo  ${jdkinstalldir}/bin/jinfo --slave /usr/bin/jstat jstat  ${jdkinstalldir}/bin/jstat --slave /usr/bin/serialver serialver  ${jdkinstalldir}/bin/serialver --slave /usr/bin/xjc xjc  ${jdkinstalldir}/bin/xjc
    #--slave /usr/bin/jmap jmap  ${jdkinstalldir}/bin/jmap 
    #--slave /usr/bin/appletviewer appletviewer 
    #--slave /usr/bin/apt apt  ${jdkinstalldir}/bin/apt

    update-alternatives --auto java
    update-alternatives --auto javac

    if [[ $(grep -c "^export JAVA_HOME=" /etc/profile) -ge 1 ]]; then
        echo "updating /etc/profile with new JAVA_HOME"
        sed -i '/^export\ JAVA_HOME/s/^/#/'
        echo "export JAVA_HOME=${jdkinstalldir}" >> /etc/profile
    else
        echo "You may need to edit files /etc/profile.d/alljava.?sh in order to put the highest priority to directory $JAVA_DIR"
    fi

    # this line is needed for ant
    if [[ ! -e /usr/lib64/jvm-exports/java-0racle ]] ; then
        mkdir -p /usr/lib64/jvm-exports/java-0racle
    fi

}

install_elasticsearch2()
{
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    echo '[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=http://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
' | sudo tee /etc/yum.repos.d/elasticsearch.repo
    yum -y install elasticsearch
    echo 'network.host: _eth0_
network.publish_host: _eth0_
cluster.name: coretech.elasticsearch
discovery.zen.ping.multicast.enabled: false
http.port: 9200
transport.tcp.port: 9300
script.engine.groovy.inline.update: on
script.inline: false
script.indexed: false
script.file: false
http.cors.enabled: true
discovery.zen.minimum_master_nodes: 1
gateway.expected_nodes: 1
node.master: true
discovery.zen.ping.unicast.hosts: ["10.223.1.4"]' | sudo tee /etc/elasticsearch/elasticsearch.yml
#discovery.zen.ping.unicast.hosts: ["10.223.1.4", "10.223.1.5", "10.223.1.6"]' | sudo tee /etc/elasticsearch/elasticsearch.yml

    systemctl enable elasticsearch
}

install_elasticsearch5()
{
    rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
    echo '[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
' | sudo tee /etc/yum.repos.d/elasticsearch.repo
    yum -y install elasticsearch
    echo 'network.host: _eth0_
network.publish_host: _eth0_
cluster.name: coretech.elasticsearch
http.port: 9200
transport.tcp.port: 9300
script.engine.groovy.inline.update: on
script.inline: false
script.ingest: false
script.file: false
http.cors.enabled: true
discovery.zen.minimum_master_nodes: 1
gateway.expected_nodes: 1
node.master: true
discovery.zen.ping.unicast.hosts: ["10.223.1.4"]' | sudo tee /etc/elasticsearch/elasticsearch.yml
##discovery.zen.ping.unicast.hosts: ["10.223.1.4", "10.223.1.5", "10.223.1.6"]' | sudo tee /etc/elasticsearch/elasticsearch.yml

    systemctl enable elasticsearch

}

start_elasticsearch()
{
    echo "Starting elasticsearch"
    systemctl start elasticsearch
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    systemctl status elasticsearch
}

restart_elasticsearch()
{
    echo "Restarting elasticsearch"
    systemctl status elasticsearch
    systemctl stop elasticsearch
    systemctl restart elasticsearch
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    systemctl status elasticsearch
}

ensure_system_updated()
{
    yum makecache fast

    echo "Updating Operating System"
    yum -y -q update
}
format_mount_datadisk()
{
    arrDev=(sdc)
    arrMount=(/var/lib/elasticsearch /data1 /data2 /data3 /data4)
    nbDev=$(echo ${arrDev[@]} | wc -w)
    i=0
    while [[ $i -lt $nbDev ]]; do
        dev=${arrDev[$i]}
        mountpoint=${arrMount[$i]}
        fdisk -l
        partition=$dev\1
        if [[ ! -e /var/lib/$dev-gpt ]] ; then
            parted -s /dev/$dev mklabel gpt
            touch /var/lib/$dev-gpt
            echo 'n
p
1


w
'|fdisk /dev/$dev
            mkfs.ext4 -F /dev/$dev
            theUUID=`blkid /dev/$dev | awk '{print $2}'  | sed 's/PARTUUID=//g' | tr -d '"'`
            echo "$theUUID      $mountpoint        ext4        defaults           0    2"
            echo "$theUUID      $mountpoint        ext4        defaults           0    2" >> /etc/fstab
            udevadm trigger
            mkdir -p $mountpoint
            mount $mountpoint
            chmod -R go+rwX $mountpoint
        fi
        i=$(($i+1))
    done
}

install_monitoring_utils()
{
    cd /opt
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    wget https://github.com/prometheus/prometheus/releases/download/v1.6.1/prometheus-1.6.1.linux-amd64.tar.gz
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    tar zxvf prometheus-1.6.1.linux-amd64.tar.gz
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    rm -f prometheus-1.6.1.linux-amd64.tar.gz
    cd /opt/prometheus-1.6.1.linux-amd64
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    touch /var/log/prometheus.log
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    touch /etc/rc.d/init.d/prometheus
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    chmod 755 /etc/rc.d/init.d/prometheus
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    cat <<'EOF' > /etc/rc.d/init.d/prometheus
#!/bin/bash
#
# /etc/rc.d/init.d/prometheus
#
# Prometheus monitoring server
#
#  chkconfig: 2345 20 80 Read
#  description: Prometheus monitoring server
#  processname: prometheus

# Source function library.
. /etc/rc.d/init.d/functions

PROGNAME=prometheus
PROG=/opt/prometheus-1.6.1.linux-amd64/$PROGNAME
USER=prometheus
LOGFILE=/var/log/prometheus.log
DATADIR=/mnt/resource/prometheus/data
LOCKFILE=/var/run/$PROGNAME.pid
CONFIG_FILE=/opt/prometheus-1.6.1.linux-amd64/prometheus.yml
ALERT_MGR_URL=localhost:9093

start() {
    echo -n "Starting $PROGNAME: "
    cd /opt/prometheus-1.6.1.linux-amd64
    #daemon --user $USER --pidfile="$LOCKFILE" "$PROG -config.file $CONFIG_FILE -storage.local.path $DATADIR -alertmanager.url $ALERT_MGR_URL &>$LOGFILE &"
    daemon --user $USER --pidfile="$LOCKFILE" "$PROG -config.file $CONFIG_FILE -storage.local.path $DATADIR &>$LOGFILE &"
    echo $(pidofproc $PROGNAME) >$LOCKFILE
    echo
}

stop() {
    echo -n "Shutting down $PROGNAME: "
    killproc $PROGNAME
    rm -f $LOCKFILE
    echo
}

case "$1" in
    start)
    start
    ;;
    stop)
    stop
    ;;
    status)
    status $PROGNAME
    ;;
    restart)
    stop
    start
    ;;
    reload)
    echo "Sending SIGHUP to $PROGNAME"
    kill -SIGHUP $(pidofproc $PROGNAME)
    ;;
    *)
        echo "Usage: service prometheus {start|stop|status|reload|restart}"
        exit 1
    ;;
esac
EOF

    groupadd -r prometheus
    useradd -r -g prometheus -s /sbin/nologin -d /mnt/resource/prometheus -c "prometheus Daemons" prometheus
    chown -R prometheus:prometheus /mnt/resource/prometheus
    chown prometheus:prometheus /var/log/prometheus.log

    echo "Add prometheus service"
    /sbin/chkconfig --del prometheus
    /sbin/chkconfig --add prometheus
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    /sbin/chkconfig prometheus off
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

    curl -Lo /etc/yum.repos.d/_copr_ibotty-prometheus-exporters.repo https://copr.fedorainfracloud.org/coprs/ibotty/prometheus-exporters/repo/epel-7/ibotty-prometheus-exporters-epel-7.repo
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    yum install -y -q node_exporter
    echo "Add node_exporter service and enable it"
    systemctl enable node_exporter.service
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi

}

start_prometheus()
{
    echo "Starting prometheus"
    systemctl enable node_exporter
    systemctl enable prometheus
    systemctl start prometheus
    systemctl start node_exporter
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    systemctl status node_exporter
    systemctl status prometheus
}

restart_prometheus()
{
    echo "Restarting prometheus"
    systemctl status node_exporter
    systemctl status prometheus
    systemctl stop node_exporter
    systemctl stop prometheus
    systemctl restart prometheus
    systemctl restart node_exporter
    if [[ $? -ne 0 ]] ; then echo "ERROR ! shell $? " ; exit 1 ; fi
    systemctl status node_exporter
    systemctl status prometheus
}



install_pre_java
install_java_oracle
install_post_java

ensure_system_updated
format_mount_datadisk

install_monitoring_utils
install_elasticsearch2

start_elasticsearch
