#!/bin/bash
. /etc/profile

ls -la /var/lib/alternatives/j*
# Possible to adjust priority by :
# vi /var/lib/alternatives/java or /var/lib/dpkg/alternatives/java
# vi/var/lib/alternatives/javac or /var/lib/dpkg/alternatives/javac
# update-alternatives --auto java
# update-alternatives --auto javac

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
# example of version : jdk-8u102-linux-x64.rpm jdk-8u92-linux-x64.rpm
# jdkver=8u102
jdkver=`echo ${jdkarch} | awk -F"-" '{print $2}'`
# jdkpriority=91080102
jdkpriority=910`echo ${jdkver} | awk -F"u" '{print $1}'`0`echo ${jdkver} | awk -F"u" '{print $2}' `
# jdkpriority=9108010
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

#jdkinstalldir=/usr/lib64/jvm/java-1.8.0-openjdk-1.8.0
# cat /var/lib/alternatives/java
# cat /var/lib/alternatives/javac
# for f in `ls $jdkinstalldir/bin` ; do  if [[ "$f" != "java" && "$f" != "javac" ]]; then printf -- '--slave /usr/bin/'$f' '$f' '$jdkinstalldir'/bin/'$f' ' ;fi; done
# sudo update-alternatives --install /usr/bin/javac javac ${jdkinstalldir}/bin/javac ${jdkpriority} --slave /usr/bin/appletviewer appletviewer /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/appletviewer --slave /usr/bin/extcheck extcheck /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/extcheck --slave /usr/bin/idlj idlj /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/idlj --slave /usr/bin/jar jar /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jar --slave /usr/bin/jarsigner jarsigner /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jarsigner --slave /usr/bin/javadoc javadoc /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/javadoc --slave /usr/bin/javah javah /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/javah --slave /usr/bin/javap javap /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/javap --slave /usr/bin/java-rmi.cgi java-rmi.cgi /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/java-rmi.cgi --slave /usr/bin/jcmd jcmd /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jcmd --slave /usr/bin/jconsole jconsole /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jconsole --slave /usr/bin/jdb jdb /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jdb --slave /usr/bin/jdeps jdeps /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jdeps --slave /usr/bin/jhat jhat /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jhat --slave /usr/bin/jinfo jinfo /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jinfo  --slave /usr/bin/jmap jmap /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jmap --slave /usr/bin/jps jps /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jps --slave /usr/bin/jrunscript jrunscript /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jrunscript --slave /usr/bin/jsadebugd jsadebugd /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jsadebugd --slave /usr/bin/jstack jstack /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jstack --slave /usr/bin/jstat jstat /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jstat --slave /usr/bin/jstatd jstatd /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jstatd --slave /usr/bin/native2ascii native2ascii /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/native2ascii --slave /usr/bin/pack200 pack200 /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/pack200  --slave /usr/bin/rmic rmic /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/rmic  --slave /usr/bin/schemagen schemagen /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/schemagen --slave /usr/bin/serialver serialver /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/serialver  --slave /usr/bin/unpack200 unpack200 /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/unpack200 --slave /usr/bin/wsgen wsgen /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/wsgen --slave /usr/bin/wsimport wsimport /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/wsimport --slave /usr/bin/xjc xjc /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/xjc
# sudo update-alternatives --install /usr/bin/java java ${jdkinstalldir}/bin/java ${jdkpriority} --slave /usr/bin/jjs jjs /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/jjs --slave /usr/bin/keytool keytool /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/keytool --slave /usr/bin/orbd orbd /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/orbd --slave /usr/bin/policytool policytool /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/policytool --slave /usr/bin/rmid rmid /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/rmid --slave /usr/bin/rmiregistry rmiregistry /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/rmiregistry --slave /usr/bin/servertool servertool /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/servertool --slave /usr/bin/tnameserv tnameserv /usr/lib64/jvm/java-1.8.0-openjdk-1.8.0/bin/tnameserv
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

update-alternatives --install /etc/init.d/jexec jexec ${jdkinstalldir}/.java/init.d/jexec ${jdkpriority}    
update-alternatives --install /usr/bin/jexec jexec ${jdkinstalldir}/lib/jexec ${jdkpriority}    

update-alternatives --auto java
update-alternatives --auto javac
update-alternatives --auto jexec
# update-alternatives --auto javap
# update-alternatives --auto javah
# update-alternatives --auto jconsole
# update-alternatives --auto jshell

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

ls -la /var/lib/alternatives/j* /var/lib/dpkg/alternatives/j*

echo "Done"
