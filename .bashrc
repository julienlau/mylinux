# sudo usermod $UESR -a -G wheel
#sudoers# %wheel ALL=(ALL) ALL
#sudoers# Defaults    timestamp_timeout=-1
# sudo openvpn --config ~/.ssh/client.ovpn
# login=jlu password=windowsPassword
# ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519
# ssh-keygen -o -t rsa -b 4096 -f ~/.ssh/id_rsa
# ## support xauth pour les applis X: 
# echo "session  optional  pam_xauth.so" >> /etc/pam.d/su

# sudo sysctl -w vm.swappiness=1
# kernel boot options : nomodeset nouveau.modeset=0 pci=noaer pci=nomsi libata.noacpi=1 nvidia-drm.modeset=1
# ubuntu nvidia: echo "options nvidia-drm modeset=1" >> /etc/modprobe.d/nvidia.conf
# ubuntu: install nvidia and blacklist nouveau; vi /etc/default/grub # GRUB_CMDLINE_LINUX="pci=nomsi" ; sudo update-grub; 
# lspci -nnk | grep -i vga -A3 | grep 'in use'
# hwinfo --gfxcard

# blkid -c /dev/null -o list
# lsblk -o name,label,partlabel,size,uuid,mountpoint
# listsmb="//prc-01-eu/DATAS //pp-prd-01-scus/logs //pp-prc-01-scus/logs //ppeu-prc-01/logs //ppeu-prd-01/logs //172.31.1.2/public"
# sudo mount.cifs //prc-01-eu/DATAS /mnt/windows -o sec=ntlm,noperm,nounix,dir_mode=0777,file_mode=0777,user=jlu,dom=GEO6,vers=2.1
# sudo mount.cifs //172.31.1.2/public /mnt/echange -o sec=ntlm,noperm,nounix,dir_mode=0777,file_mode=0777,user=jlu,dom=GEO6,vers=2.1
# sudo mount -t ntfs -o "rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other" "/dev/sdc2" "/mnt/ntfs-d"

# egrep -v '^#' /etc/systemd/journald.conf 
# SystemMaxUse=3G
# MaxRetentionSec=1month
# MaxFileSec=1week
# sudo journalctl --rotate
# sudo journalctl --vacuum-time=10minute

# ecryptfs-simple /path/to/foo /path/to/bar

# sudo certbot certonly --standalone --preferred-challenges http -d example.com
# sudo certbot certonly --webroot -w /var/www/example -d www.example.com ### /var/www/example is a directory

# tar compress parallel
# tar -I "xz -T0" -cf archive.tar.xz ./file.csv
# XZ_OPT='-T0 -9' tar -cJf archive.tar.xz ./file.csv
export XZ_OPT='-T0'

# docker run -d --name=netdata   -p 19999:19999   -v netdataconfig:/etc/netdata   -v netdatalib:/var/lib/netdata   -v netdatacache:/var/cache/netdata   -v /etc/passwd:/host/etc/passwd:ro   -v /etc/group:/host/etc/group:ro   -v /proc:/host/proc:ro   -v /sys:/host/sys:ro   -v /etc/os-release:/host/etc/os-release:ro   --restart unless-stopped   --cap-add SYS_PTRACE   --security-opt apparmor=unconfined   netdata/netdata

test -s ~/.alias && . ~/.alias || true

# Source global definitions
if [ -e /etc/bashrc ]; then
    source /etc/bashrc
fi

if [ -e ~/.xsh ]; then
    source ~/.xsh
fi

# Ubuntu 22.04 desktop
bind 'set enable-bracketed-paste off' 2>/dev/null

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

export myshell=$(which bash)
export kernelver=$(uname -s)$(uname -r)
if [[ ! -z $(which lsb_release 2>/dev/null) ]] ; then
    export linuxDistro=`lsb_release -i | awk -F ':' '{print $2}' | xargs echo`
    export linuxDistroVer=`lsb_release -d | awk -F ':' '{print $2}' | xargs echo`
fi
#export osname=`python -c 'import sys; sys.path.append("/usr/lib/python2.6/site-packages/"); from ambari_commons import OSCheck; print OSCheck.get_os_family()'`
#export osversion=`python -c 'import sys; sys.path.append("/usr/lib/python2.6/site-packages/"); from ambari_commons import OSCheck; print OSCheck.get_os_major_version()'`
export platform=$(uname -s)
if [[ "$USER" = "root" ]]; then
    export HOME=/root
fi
#export user=$USER
if [[ -z $HOST && -z $HOSTNAME  ]] ; then
    export HOST="$(uname -n)"
    export HOSTNAME="$(uname -n)"
elif [[ -z $HOST && ! -z $HOSTNAME ]] ; then
    export HOST=$HOSTNAME
elif [[ ! -z $HOST && -z $HOSTNAME  ]] ; then
    export HOSTNAME=$HOST
fi
export tabulation=`echo -e "\t"`
# export pyver=`python -c 'import platform; major, minor, patch = platform.python_version_tuple(); print(f"{major}.{minor}")'`
#============================================================
export mylistSsh=$(grep -v -e "^#" -e "localhost" /etc/hosts | sed '/^$/d' | grep "^[0-9]" | awk '{print $2}' | sort | uniq)
export allhost=($(grep -v -e "^#" -e "localhost" /etc/hosts | sed '/^$/d' | grep "^[0-9]" | awk '{print $2}'))
export allip=($(grep -v -e "^#" -e "localhost" /etc/hosts | sed '/^$/d' | grep "^[0-9]" | awk '{print $1}'))
#============================================================
# Functions (1)
#
##
# serialize_array
# Serializes a bash array to a string, with a configurable seperator.
#
# $1 = source varname ( contains array to be serialized )
# $2 = target varname ( will contian the serialized string )
# $3 = seperator ( optional, defaults to $'\x01' )
#
# example:
#
#    my_arry=( one "two three" four )
#    serialize_array my_array my_string '|'
#    declare -p my_string
#
# result:
#
#    declare -- my_string="one|two three|four"
#
function serialize_array() {
    declare -n _array="${1}" _str="${2}" # _array, _str => local reference vars
    local IFS="${3:-$'\x01'}"
    # shellcheck disable=SC2034 # Reference vars assumed used by caller
    _str="${_array[*]}" # * => join on IFS
}

##
# deserialize_array
# Deserializes a string into a bash array, with a configurable seperator.
#
# $1 = source varname ( contains string to be deserialized )
# $2 = target varname ( will contain the deserialized array )
# $3 = seperator ( optional, defaults to $'\x01' )
#
# example:
#
#    my_string="one|two three|four"
#    deserialize_array my_string my_array '|'
#    declare -p my_array
#
# result:
#
#    declare -a my_array=([0]="one" [1]="two three" [2]="four")
#
function deserialize_array() {
    IFS="${3:-$'\x01'}" read -r -a "${2}" <<<"${!1}" # -a => split on IFS
}

unalias sudisp 2>/dev/null
sudisp()
{
    usr=$1
    echo $DISPLAY
    xauth list $DISPLAY
    xdis=`xauth list $DISPLAY | grep -v '^#' | head -1`
    dis=$DISPLAY
    sudo su - $usr
    export DISPLAY=$dis
    xauth add $xdis
}

unalias sourceprop 2>/dev/null
sourceprop()
{
    javaproperties=$1
    source <(awk 'BEGIN {
    FS="=";
    n="";
    v="";
    c=0; # Not a line continuation.
}
/^#/ { # The line is a comment.  Breaks line continuation.
    c=0;
    next;
}
/\\$/ && (c==0) && (NF>=2) { # Name value pair with a line continuation...
    e=index($0,"=");
    n=substr($0,1,e-1);
    v=substr($0,e+1,length($0) - e - 1);    # Trim off the backslash.
    c=1;                                    # Line continuation mode.
    next;
}
/^[^\\]+\\$/ && (c==1) { # Line continuation.  Accumulate the value.
    v= "" v substr($0,1,length($0)-1);
    next;
}
((c==1) || (NF>=2)) && !/^[^\\]+\\$/ { # End of line continuation, or a single line name/value pair
    if (c==0) {  # Single line name/value pair
        e=index($0,"=");
        n=substr($0,1,e-1);
        v=substr($0,e+1,length($0) - e);
    } else { # Line continuation mode - last line of the value.
        c=0; # Turn off line continuation mode.
        v= "" v $0;
    }
    # Make sure the name is a legal shell variable name
    gsub(/[^A-Za-z0-9_]/,"_",n);
    # Remove newlines from the value.
    gsub(/[\n\r]/,"",v);
    print n "=\"" v "\"";
    n = "";
    v = "";
}
END {
}' ${javaproperties})
}

unalias exporte 2>/dev/null
# avoid to export keys (like PATH or LD_LIBRARYPATH) to value pointing to non existing path or including duplicates
exporte()
{
    # usage: 
    # exporte titi=/usr/bin:/opt/bin ; echo $titi ;  exporte titi=$titi:~/bin ; echo $titi;  exporte titi=$titi:/trou/duc 
    key=`echo $1 | awk -F '=' '{print $1}'`
    valOld=$(echo ${!key})
    vals=$(echo $1 | awk -F '=' '{print $2}')
    valArr=($(echo $vals | sed 's/^://' | sed 's/:/ /g' ))
    unset valstrtmp
    for val in ${valArr[@]}; do 
        if [[ -e $val || ! -z $(ls $val 2>/dev/null) ]] ; then                   #if path exists
            if [[ -z $valstrtmp ]] ; then             #key is initialized if void
                valstrtmp=$val
            elif [[ -z $(echo $valstrtmp | grep -e "^$val:" -e ":$val:" -e ":$val$") ]] ; then  #else it is incremented
                valstrtmp=$valstrtmp:$val
            fi
        # else
        #     echo "Warning ! path $val does not exist and was ignored for key $key by function exporte"
        fi
    done
    if [[ -z $valstrtmp && ! -z $valOld && -e $valOld ]]; then
        export $key=$valOld
    else
        export $key=$valstrtmp
    fi
}

unalias exportNoVoid 2>/dev/null
# avoid to export keys (like PATH or LD_LIBRARYPATH) to value pointing to non existing path or including duplicates
exportNoVoid()
{
    # usage: 
    # exporte titi=/usr/bin:/opt/bin ; echo $titi ;  exporte titi=$titi:~/bin ; echo $titi;  exporte titi=$titi:/trou/duc 
    key=`echo $1 | awk -F '=' '{print $1}'`
    vals=$(echo $1 | awk -F '=' '{print $2}')
    valArr=($(echo $vals | sed 's/^://' | sed 's/:/ /g' ))
    unset valstrtmp
    for val in ${valArr[@]}; do 
        if [[ -e $val || ! -z $(ls $val 2>/dev/null) ]] ; then                   #if path exists
            if [[ -z $valstrtmp ]] ; then             #key is initialized if void
                valstrtmp=$val
            elif [[ -z $(echo $valstrtmp | grep -e "^$val:" -e ":$val:" -e ":$val$") ]] ; then  #else it is incremented
                valstrtmp=$valstrtmp:$val
            fi
        # else
        #     echo "Warning ! path $val does not exist and was ignored for key $key by function exporte"
        fi
    done
    if [[ ! -z $valstrtmp ]]; then
        export $key=$valstrtmp
    fi
}

unalias myip 2>/dev/null
myip()
{
    ip route get 8.8.8.8 2>/dev/null | awk '{ for(i=1; i<NF; i++) { if($i == "src") {print $(i+1); exit} } }'
    # ip addr show dev eth1 primary | awk '/(inet .*\/)/ { print $2 }' | cut -d'/' -f1
}

unalias spfy 2>/dev/null
spfy()
{
    if [[ $# -eq 0 ]]; then
        # spotify pause
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
    elif [[ "$1" = "n" ]]; then
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next
    else
        dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous
    fi
}

unalias disownall 2>/dev/null
disownall()
{
    list=$(jobs -l 2>/dev/null | awk '{print $2}')
    if [[ ! -z $list ]] ; then
        echo $list
        disown $list
    fi
}

unalias dateDaystoMs 2>/dev/null
dateDaystoMs()
{
    if [[ $# -eq 1 ]]; then
        day=$1
        echo "$day *24.0*60.0*60.0*1000.0" | bc
    else
        echo "ERROR ! 1/ day"
    fi
}

unalias dateJtoH 2>/dev/null
dateJtoH()
{
    if [[ $# -eq 2 && $2 -le 366 ]]; then
        year=$1
        day=$2
        date -d "${year}-01-01 +$(( ${day} - 1 ))days" +%Y-%m-%d
    else
        echo "ERROR ! 1/ year 2/ day Julian"
    fi
}

unalias dateJtoEpoch 2>/dev/null
dateJtoEpoch()
{
    if [[ $# -eq 2 && $2 -le 366 ]]; then
        year=$1
        day=$2
        date -d "${year}-01-01 +$(( ${day} - 1 ))days" +%s
    else
        echo "ERROR ! 1/ year 2/ day Julian"
    fi
}

unalias dateEpochToH 2>/dev/null
dateEpochToH()
{
    date -d @$1 +%Y-%m-%dT%H:%M:%S' '%z
}

unalias dateDaysFromEpoch 2>/dev/null
dateDaysFromEpoch()
{
    date -d @$(echo "$1 * 86400"  | bc) +%Y-%m-%d' '%z
}

unalias dateEpoch 2>/dev/null
dateEpoch()
{
    date +%s
}

unalias dateEpochMs 2>/dev/null
dateEpochMs()
{
    echo $(($(date +%s%N)/1000000))
}

unalias dateEpochUsToH 2>/dev/null
dateEpochUsToH()
{
    v=`echo $1 / 1000000 | bc`
    date -d @$v +%Y-%m-%dT%H:%M:%S.%N' '%z
}

unalias dateEpochmicros 2>/dev/null
dateEpochUs()
{
    echo $(($(date +%s%N)/1000))
}

unalias gitlabci 2>/dev/null
gitlabci()
{
    # arg $1 is the name of the stage in your file .gitlab-ci.yml
    docker run --rm -w $PWD -v $PWD:$PWD -v /var/run/docker.sock:/var/run/docker.sock gitlab/gitlab-runner:latest exec docker $1
}

unalias poetrya 2>/dev/null
poetrya()
{
    poetryaPath=$1
    if [[ -e $poetryaPath/pyproject.toml ]]; then
        pwd
        cd $poetryaPath
        poetry env list
        poetry env info --path
        poetry shell
    elif [[ -e $poetryaPath/bin/activate ]]; then
        pwd
        source $poetryaPath/bin/activate
    else
        poetrylist
        echo "ERROR ! poetry env not found at $poetryaPath"
    fi
}

unalias poetrylist 2>/dev/null
poetrylist()
{
    if [[ -e pyproject.toml ]]; then
        poetry env list
        poetry env info --path
    fi
    poetryList=`poetry config virtualenvs.path`
    ls -lad $poetryList/*-py[0-9]*
}

unalias dockernodexporter 2>/dev/null
dockernodexporter()
{
    ss -tulpn | grep 9100
    nodeuid=`cat /etc/passwd | grep node_exporter | awk -F ':' '{print $3}'`
    docker run -d -p 9100:9100 --user ${nodeuid}:${nodeuid} -v "/:/hostfs" --net="host" prom/node-exporter:v0.18.1 --path.rootfs=/hostfs
    ss -tulpn | grep 9100
}

# Function dockercleanv
unalias dockercleanv 2>/dev/null
dockercleanv()
{
    pattern=`echo "$*" | sed -e 's: :\\\|:g'`
    docker volume ls 2>&1 | grep -- "$pattern"
    parent=`docker volume rm $* 2>&1 | grep 'volume is in use' | awk '{print $NF}' | tr -d '[]'`
    parent=`echo $parent`
    if [[ ! -z $parent ]]; then
        for id in $parent; do 
            docker inspect $id | jq '.[] | .Name, .Id '
        done
    docker stop $parent
    docker rm $parent
    docker volume rm $*
    fi
}

# Function dockercleani
unalias dockercleani 2>/dev/null
dockercleani()
{
    docker images | awk '$2 ~ /<none>/' 
    docker images | awk '$2 ~ /<none>/' | awk '{print $3}' | grep -v IMAGE | xargs docker rmi -f
    echo "you may want to also run to clean networks and more : docker system prune"
}

# Function dockerclean
unalias dockerclean 2>/dev/null
dockerclean()
{
    docker rm $(docker ps -qa --filter status=exited)
    docker volume prune -f
    docker image prune -a -f
    docker images | awk '$2 !~ /^[[:digit:]]*$|^[0-9.]*$|latest|master|base/' 
    docker images | awk '$2 !~ /^[[:digit:]]*$|^[0-9.]*$latest|master|base/' | awk '{print $3}' | grep -v IMAGE | xargs docker rmi -f
}

unalias dockerbuild 2>/dev/null
dockerbuild()
{
    myimage=$(basename `pwd`)
    if [[ $# -eq 0 ]]; then
        for f in $(ls *.dockerfile); do
            echo "===================>>> docker build image described by $f to $myimage:${f%.dockerfile}"
            cat $f > ${f%.dockerfile}.log
            docker build --progress=plain -t $myimage:${f%.dockerfile} -f $f . 2>&1 | tee -a ${f%.dockerfile}.log
            docker image prune -f
        done
        f=Dockerfile
    else
        f=$1
    fi
    if [[ -e $f ]]; then
        echo "===================>>> docker build image described by $f to $myimage:${f%.dockerfile}"
        cat $f > ${f%.dockerfile}.log
        docker build --progress=plain -t $myimage:${f%.dockerfile} -f $f .  2>&1 | tee -a ${f%.dockerfile}.log
    fi
}

unalias dockerlogs 2>/dev/null
dockerlogs() {
    if [[ $# -eq 0 ]]; then
        echo "ERROR : please providing a query string to grep !"
    else
        journalctl -u docker CONTAINER_ID=$1 | grep -i -v -e Elasticsearch -v -e ']: $' -v -e '  No living connections' -e '  No living connections' -e 'GET /healthz' -e 'lib.request_handlers.authentication - info - No bearer token found on request'

        echo "journalctl -u docker --since=-5m CONTAINER_ID=$1 | grep -i -v -e Elasticsearch -e ']: $' -e '  No living connections' -e '  No living connections' -e 'GET /healthz' -e 'lib.request_handlers.authentication - info - No bearer token found on request'
"
    fi
}

unalias dockerjlog 2>/dev/null
dockerjlog() {
    if [[ $# -eq 0 ]]; then
        echo "ERROR : please providing a query string to grep !"
    else
        journalstr=""
        for str in $* ; do
            ids=`docker ps | grep $str | awk '{print $1}'`
            if [[ ! -z $ids ]]; then
                for id in $ids; do 
                    journalstr="CONTAINER_ID=$id $journalstr"
                done
            fi
        done
        journalctl -u docker --since=-5m $journalstr | grep -i -v -e Elasticsearch -v -e ']: $' -v -e '  No living connections' -e '  No living connections' -e 'GET /healthz' -e 'lib.request_handlers.authentication - info - No bearer token found on request'

        echo "journalctl -u docker --since=-5m $journalstr | grep -i -v -e Elasticsearch -e ']: $' -e '  No living connections' -e '  No living connections' -e 'GET /healthz' -e 'lib.request_handlers.authentication - info - No bearer token found on request'
"
    fi
}

unalias dockerhist 2>/dev/null
dockerhist() {
    docker history --no-trunc "$1" | \
        sed -n -e 's,.*/bin/sh -c #(nop) \(MAINTAINER .*[^ ]\) *0 B,\1,p' | \
        head -1
    docker inspect --format='{{range $e := .Config.Env}}
ENV {{$e}}
{{end}}{{range $e,$v := .Config.ExposedPorts}}
EXPOSE {{$e}}
{{end}}{{range $e,$v := .Config.Volumes}}
VOLUME {{$e}}
{{end}}{{with .Config.User}}USER {{.}}{{end}}
{{with .Config.WorkingDir}}WORKDIR {{.}}{{end}}
{{with .Config.Entrypoint}}ENTRYPOINT {{json .}}{{end}}
{{with .Config.Cmd}}CMD {{json .}}{{end}}
{{with .Config.OnBuild}}ONBUILD {{json .}}{{end}}' "$1"
}

# Function grepsrc
# Example of direct find cmd: 
# find . -name "*.go" ! -name  '*_doc_generated.go'  ! \( -path '*/vendor/*' -o -path '*/test/*' -o -path '*/rbac/*' \) | xargs grep -ri --color leader
# find . -name "*.go" ! -name  '*_doc_generated.go'  ! \( -path '*/vendor/*' -o -path '*/test/*' -o -path '*/rbac/*' -o -path '*/metrics/*' -o -path '*/testing/*' \) | xargs grep -ri --color watch
unalias grepsrc 2>/dev/null
grepsrc()
{
    searchpath=.
    expression=''
    opt=''
    if [[ $# -eq 3 ]] ; then
        searchpath=$1
        opt=$2
        expression=$3
    elif [[ $# -eq 2 ]] ; then
        opt=$1
        expression=$2
    else
        expression=$1
    fi
    find $searchpath ! \( -path '*/node_modules/*' -o -path '*/vendor/*' \) \( -name '.*.yaml' -o -name '.*.yml' -o -name '*.yaml' -o -name '*.yml' -o -name '*.go' -name '*.for' -o -name '*.f' -o -name '*.F' -o -name '*.h' -o -name '*.F90' -o -name '*.f90' -o -name '*.m' -o -name '*.M' -o -name '*.py' -o -name '*.c' -o -name '*.C' -o -name '*.cpp' -o -name '*.CPP' -o -name '*.c++' -o -name '*.C++' -o -name '*.H' -o -name '*.inc' -o -name '*.?sh' -o -name '*.??sh' -o -name '*.sh' -o -name '*.java' -o -name '*.scala' -o -name '*.julia' -o -name '*.js' -o -name '*.go' -o -name '*.php' -o -name '*.perl' -o -name '*.sbt' -o -name 'pom.xml' -o -name '*.t' \) -print 2>/dev/null | xargs grep --color -s $opt -- $expression
}
# end Function grepsrc

# Function grepjs
unalias grepjs 2>/dev/null
grepjs()
{
    searchpath=.
    expression=''
    opt=""
    if [[ $# -eq 3 ]] ; then
        opt=$1
        expression=$2
        searchpath=$3
    elif [[ $# -eq 2 ]] ; then
        expression=$1
        searchpath=$2
    else
        expression=$1
    fi
    find $searchpath -name '*.js' -print 2>/dev/null | xargs grep --color -s $opt -- $expression
}
# end Function

# Function greppy
unalias greppy 2>/dev/null
greppy()
{
    searchpath=.
    expression=''
    opt=""
    if [[ $# -eq 3 ]] ; then
        opt=$1
        expression=$2
        searchpath=$3
    elif [[ $# -eq 2 ]] ; then
        expression=$1
        searchpath=$2
    else
        expression=$1
    fi
    find $searchpath \( -name '*.py' -o -name '*.?sh' -o -name '*.??sh' -o -name '*.sh' \) -print 2>/dev/null | xargs grep --color -s $opt -- $expression
}
# end Function

unalias inList 2>/dev/null
inList() 
{
    local search="$1"
    shift
    local list=("$@")
    for file in "${list[@]}" ; do
        [[ "$file" == "$search" ]] && echo "1" && return
    done
    echo "0"
}

# Function grepc
unalias grepc 2>/dev/null
grepc()
{
    list=$(find ./ \( -name "./.*" -prune -name "*/target/*" -o -print \) 2>/dev/null | xargs grep --binary-files=without-match --no-message -s -c -i $1 | grep -v ":0" | awk -F ":" '{sum+=$NF} END {print sum}')
}
# end Function

# Function 
unalias psup 2>/dev/null
psup()
{
    time="00:00"
    elaspedSeconds=0
    if [[ $# -eq 1 ]] ; then
        psargument=$1
        time=`ps -eo pid,etime,time,comm,args | grep -v " grep " | grep $psargument | awk '{ print $2}' | tail -1`
        # minute: mm:ss
        # hours: hh:mm:ss
        # days: d-hh:mm:ss
        #echo $time
        days=0
        hours=0
        minutes=0
        seconds=0
        if [[ $(echo $time | grep -c -- '\-') -gt 0 ]]; then
            days=$(echo $time | awk -F '-' '{print $1}')
            hours=$(echo $time | awk -F '-' '{print $2}' | awk -F ':' '{printf "%d\n", $1}' )
            minutes=$(echo $time | awk -F '-' '{print $2}' | awk -F ':' '{printf "%d\n", $2}' )
            seconds=$(echo $time | awk -F '-' '{print $2}' | awk -F ':' '{printf "%d\n", $3}' )
        elif [[ $(echo $time | grep -o -- ':' | wc -l) -eq 2 ]]; then
            hours=$(echo $time | awk -F ':' '{printf "%d\n",$1}' )
            minutes=$(echo $time | awk -F ':' '{printf "%d\n",$2}' )
            seconds=$(echo $time | awk -F ':' '{printf "%d\n",$3}' )
        elif [[ $(echo $time | grep -o -- ':' | wc -l) -eq 1 ]]; then
            minutes=$(echo $time | awk -F ':' '{printf "%d\n", $1}' )
            seconds=$(echo $time | awk -F ':' '{printf "%d\n", $2}' )
        fi
        elaspedSeconds=$(python -c "print (($days*24+$hours)*60+$minutes)*60+$seconds")
    fi
    echo $elaspedSeconds
}
# end Function

# Function zpop
unalias zpop 2>/dev/null
zpop()
{
    max=`dirs | tail -1 | awk '{ print $1 }'`
    max=`echo $max`
    target=$1
    i=$max
    while [[ $i -gt $target && $i -gt 1 ]] ; do
        popd $i 2>&1 >/dev/null
        i=$(($i-1))
    done
}
# end Function zpop

# Function lsd
unalias lsd 2>/dev/null
lsd()
{
    if [[ $# -ge 0 ]]; then
        path=$1
    else
        path=$(pwd)
    fi
    \ls -l $path | awk 'NR!=1 && /^d/ {print $NF}'
}
# end Function lsd

# Function findfor
unalias findfor 2>/dev/null
findfor()
{
    find $1 \( -name '*.for' -o -name '*.f' -o -name '*.F' -o -name '*.h' -o -name '*.F90' -o -name '*.f90' \) -print 2>/dev/null
}
# end Function findfor

# Function upper_case
unalias i_upper_case 2>/dev/null
i_upper_case()
{
    echo $1 | tr '[:lower:]' '[:upper:]'
}
#

# Function ffind
unalias ffind 2>/dev/null
ffind()
{
    zn=$(echo $1 | tr '[:lower:]' '[:upper:]')
    find . \( -name "*$1*" -o -name "*$zn*" \) 2>/dev/null
}
# end Function ffind

# Function digit2
unalias digit2 2>/dev/null
digit2()
{
    # if available: typeset -Z2 $1
    echo $1 |awk ' { printf "%02d\n", $0 } '
}
# End Function digit2
# Function digit3
unalias digit3 2>/dev/null
digit3()
{
    # if available: typeset -Z2 $1
    echo $1 |awk ' { printf "%03d\n", $0 } '
}
# End Function digit3

# Function digit4
unalias digit4 2>/dev/null
digit4()
{
    # if available: typeset -Z4 $1
    echo $1 |awk ' { printf "%04d\n", $0 } '
}
# End Function digit4

# Function digit6
unalias digit6 2>/dev/null
digit6()
{
    # if available: typeset -Z4 $1
    echo $1 |awk ' { printf "%06d\n", $0 } '
}
# End Function digit6

# Function digitn
unalias digitn 2>/dev/null
digitn()
{
    # if available: typeset -Z$2 $1
    i=0000000000000000000000000000000000000$1
    n=1
    fmt=''
    while [[ $n -le $2 && $n -le 16 ]] ; do
        fmt=$fmt'.'
        n=$(($n+1))
    done
    fmt='.*\('$fmt'\)'
    expr $i : "$fmt"
}
# End Function digitn

# Function mediaexp
unalias mediaexp 2>/dev/null
mediaexp()
{
    prefix=''
    followlinks=1
    if [[ $# -eq 1 ]] ; then
        dest=$1
    elif [[ $# -eq 2 ]] ; then
        dest=$1
        followlinks=$2
    elif [[ $# -eq 3 ]] ; then
        dest=$1
        prefix=$3
    else
        dest=/tmp
    fi
    if [[ ! -d $dest ]] ; then 
        echo "Error ! directory $d does not exist"
    else
        if [[ $followlinks -eq 1 || $followlinks = "lnk" || $followlinks = "-L" ]] ; then
            list=`find -L . \( -name "*.gif" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.avi" -o -name "*.eps" -o -name "*.ps" -o -name "*.pdf" -o -name "trac_resi*.log" -o -name "gplot*.log" ! -name "*-it[0-9][0-9][0-9][0-9].jpg" ! -name "*-it[0-9][0-9][0-9][0-9][0-9][0-9].jpg" \) -type f`
        else
            list=`find -H . \( -name "*.gif" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.avi" -o -name "*.eps" -o -name "*.ps" -o -name "*.pdf" -o -name "trac_resi*.log" -o -name "gplot*.log" ! -name "*-it[0-9][0-9][0-9][0-9].jpg" ! -name "*-it[0-9][0-9][0-9][0-9][0-9][0-9].jpg" \) -type f`
        fi
        list=$(echo $list)
        echo $list
        for f in $list ; do 
            if [[ $dest != $(dirname ${f#./} | tr -s '/' ' ' | awk '{ print $1 }') && ! -z $(echo $f | grep -v -- -it[0-9][0-9][0-9][0-9].jpg | grep -v -- -it[0-9][0-9][0-9][0-9][0-9][0-9].jpg) ]] ; then 
                nf=$(echo "$prefix${f#./}" | sed 's:\.\/::g' | sed 's:\/:-:g' )
                #cp $f $dest/$nf
                #echo "cp $f $dest/$nf"
                rsync -tu $f $dest/$nf
                echo "rsync -tu $f $dest/$nf"
            fi
        done
        echo "Copy in $dest OK"
    fi
}

unalias sshi 2>/dev/null
sshi() {
    i=$1
    af=`echo ${i} |cut -c 1`
    if [[ `echo "${HOSTNAME}" | tr '[:upper:]' '[:lower:]'` = "af${af}" ]]; then
        echo "ssh -X 192.168.122.${i}"

        ssh -X 192.168.122.${i}
    else
        echo "ssh -X -p 22${i} 192.168.60.20${af}"
        ssh -X -p 22${i} 192.168.60.20${af}
    fi
}

unalias sshRedir 2>/dev/null
sshRedir() {
    port_ssh=22 #default on azure is 2200 instead of 22 normally
    port_dist=80
    port_local=$port_dist
    if [[ $# -ge 1 ]] ; then
        dest=$1
    else
        echo "need a destination host in input"
        return
    fi
    if [[ $# -ge 2 ]] ; then
        port_dist=$2
        port_local=$port_dist
    fi
    if [[ $# -ge 3 ]] ; then
        port_local=$3
    fi
    if [[ $# -ge 4 ]] ; then
        port_ssh=$4
    fi
    netstat -anpe | grep ":$port_dist"
    echo "sudo ssh -L $port_dist:localhost:$port_local -f -N ec2-user@$dest -p $port_ssh"
    sudo ssh -L $port_dist:localhost:$port_local -f -N ec2-user@$dest -p $port_ssh
}

unalias jarls 2>/dev/null
jarls() {
    if [[ $# -eq 1 ]] ; then
        zjar=$1
    else
        echo "need a jar in input"
        return
    fi
    jar tvf $zjar | grep ".class" | awk '{print $NF}' | sed "s/.class//g" | sed "s:\\$\\$:\\$ :g"  | awk '{print $1}' | tr -s '/' '.' | sort | uniq
}
# list=$(jar tvf $zjar | grep ".class" | awk '{print $NF}' | sed "s/.class//g" | sed "s:\\$\\$:\\$ :g"  | awk '{print $1}' | tr -s '/' '.' | sort | uniq) && for c in $list; do echo "log4j.appender.$c=INFO, graylog2"; done

unalias yarnFails 2>/dev/null
yarnFails() {
    if [[ $# -ge 1 ]] ; then
        yarn application -list -appStates ALL 2>/dev/null | sed "1,2d" | grep -e FAILED | grep -e $@
    else
        yarn application -list -appStates ALL 2>/dev/null | sed "1,2d" | grep -e FAILED
    fi
}

unalias yarnq 2>/dev/null
yarnq() {
    if [[ $# -ge 1 ]] ; then
        yarn application -list -appStates ALL 2>/dev/null | sed "1,2d" | grep -e RUNNING -e ACCEPTED | grep -e $@
    else
        yarn application -list -appStates ALL 2>/dev/null | sed "1,2d" | grep -e RUNNING -e ACCEPTED
    fi
}

unalias yarnk 2>/dev/null
yarnk() {
    if [[ $# -ge 1 ]] ; then
        for theapp in $@ ; do 
            yarn application -kill $theapp
        done
    fi
}

unalias yarnlog 2>/dev/null
yarnlog() {
    if [[ $# -eq 1 ]] ; then
        appid=$1
    else
        echo "need an applicationId in input"
        return
    fi
    yarn logs -applicationId $appid > yarn_$appid.log 2>&1
    echo "see file yarn_$appid.log"
}

unalias yarnchk 2>/dev/null
yarnchk() {
    if [[ $# -eq 1 ]] ; then
        appid=$1
    else
        echo "need an applicationId in input or file in *.log"
        return
    fi
    tab=`echo -e "\t"`
    if [[ $appid = ${appid%.log} || ! -e $appid ]] ; then
        #yarn logs -applicationId $appid 2>/dev/null | grep -v '^#' | grep -e "^java.lang." -e "^$tab\at " -e " ERROR " -e "^java.io" -e "FileNotFound"
        yarn logs -applicationId $appid > yarn_$appid.log 2>&1
        flog=yarn_$appid.log
    else
        flog=$appid
    fi
    grep -v -e '^#' -v -e "disassociated! Shutting down." $flog | grep -e "^java.lang." -e " ERROR " -e "^java.io" -e "FileNotFoundException" -e "not serializable" -e "^$tab\at "
}

unalias offsetKafkaCompute 2>/dev/null
offsetKafkaCompute() {
    yarn logs -applicationId $(yarnq | grep KAFKACompute | awk '{print $1}') -size -102400000 2>/dev/null | grep offset  | tail -59 | awk -F '/' '{SUM+=$NF}END{print SUM}'
}

unalias offsetKafkaConsumer 2>/dev/null
offsetKafkaConsumer() {
    groupid=topictest
    nbpart=59
    servers=dcos-kafka-32736118-0:9092,dcos-kafka-32736118-1:9092,dcos-kafka-32736118-2:9092
    kafka-consumer-groups.sh --describe --new-consumer --bootstrap-server ${servers} --group ${groupid} > $tmpstr 2>&1
    kafkaLag=`tail -${nbpart} $tmpstr | awk '{SUM+=$6}END{print SUM}'`
    echo "Summed lag for consumer with groupid ${groupid} = $kafkaLag"
}

unalias hdiCheck 2>/dev/null
hdiCheck() {
    for h in $mylistSshHdi ; do  ssh $h ". /etc/profile ; uname -n; ls -lrt parquet*.log" 2>/dev/null; done
}

unalias hdiCheckTail 2>/dev/null
hdiCheckTail() {
    for h in $mylistSshHdi ; do  ssh $h ". /etc/profile ; uname -n; tail parquet*.log" 2>/dev/null; done
}

unalias ycheck 2>/dev/null
ycheck() {
    python -c "from yaml import load, Loader; load(open('$1'), Loader=Loader)" 
}

unalias zkmon 2>/dev/null
zkmon() {
    export zkhost=$1
    printf "${zkhost} " ; echo ruok | nc ${zkhost} 2181 ; echo ""
    printf "${zkhost} " ; echo mntr | nc ${zkhost} 2181 ; echo "" 
    printf "${zkhost} " ; echo stat | nc ${zkhost} 2181 ; echo "" 
}

# Mesos API
# curl -X GET http://$mesosMaster:5050/redirect # return leading master
# curl -X GET http://$mesosMaster:5050/flags # return master config
# curl -X GET http://$mesosMaster:5050/mesos/master/metrics/snapshot -o master_metrics.json
# curl -X GET http://$mesosMaster:5050/master/tasks -o master_tasks.json
# curl -X GET http://<marathon-ip>:8080/metrics
# curl -X GET http://<cluster>/system/v1/agent/<agent_id>/metrics/v0/<resource_path>
# curl -X GET http://<mesos-agent-ip>:5051/metrics/snapshot
# curl -X GET http://$mesosMaster:5050/master/frameworks -o master_frameworks.json
# see dcos tasks associated to a given framework id
# If you have a dc/os diagnostic bundle from the cluster before the teardown, you can see the tasks with something like this run from within one of the master dirs (substituting <framework-id> for the framework ID that you tore down):
# echo -e "ID NAME ROLE SLAVE_ID STATE\n $(jq -r '.frameworks[] | select(.id == "<framework-id>") | .tasks[] | "\(.id) \(.name) \(.role) \(.slave_id) \(.state)"' master_frameworks.json | sort -k 5)" | column -t

unalias lsMesosFramework 2>/dev/null
lsMesosFramework() {
    export mesosMaster=$1
    export frameworkId=$2
    echo "ID NAME ROLE SLAVE_ID STATE"
    curl -X GET http://$mesosMaster:5050/master/frameworks 2>/dev/null | jq -r '.frameworks[] | select(.id == "'${frameworkId}'") | .tasks[] | "\(.id) \(.name) \(.role) \(.slave_id) \(.state)"' | column -t
}

unalias lsMesosTask 2>/dev/null
lsMesosTask() {
    export mesosMaster=$1
    export status=$2
    # status = TASK_RUNNING TASK_ERROR TASK_FAILED TASK_KILLED TASK_LOST TASK_FINISHED TASK_STAGING
    echo "ID NAME ROLE SLAVE_ID STATE"
    curl -X GET http://$mesosMaster:5050/master/tasks 2>/dev/null | jq -r '.tasks[] | select(.state == "'${status}'") | .tasks[] | "\(.id) \(.name) \(.role) \(.slave_id) \(.state)"' | column -t
}

unalias killMesosFramework 2>/dev/null
killMesosFramework() {
    mesosMaster=$1
    frameworkId=$2
    echo "curl -X POST http://$mesosMaster:5050/master/teardown -d \"frameworkId=$frameworkId\""
    curl -X POST http://$mesosMaster:5050/master/teardown -d "frameworkId=$frameworkId"
}

unalias dcosCleanMarathon 2>/dev/null
dcosCleanMarathon() {
    zkhost=10.253.3.200:2181
    zkpath=/marathon/state/apps
    appName=$1
    if [[ $# -ge 2 ]]; then
        zkhost=$2
    fi
    if [[ $appName != '' ]] ; then
        for d in {a..f} {0..9}; do 
            zkCli.sh -server $zkhost rmr $zkpath/$d/$appName 2>&1 | grep -v -e '^$' -e 'log4j:WARN ' -e 'WATCHER::' -e 'WatchedEvent state:SyncConnected type:None path:null'
        done
    fi
}

unalias dcosDeploy 2>/dev/null
dcosDeploy() { 
    mesosMaster=10.253.3.200
    mode=marathon
    if [[ $# -ge 2 ]] ; then
        mesosMaster=$1
        jsonConfig=$2
    else
        return
    fi
    if [[ ! -e $jsonConfig ]]; then
        echo "ERROR file not found : $jsonConfig"
        return
    fi
    if [[ `grep -ci '"schedules"' $jsonConfig` -gt 0 || `echo $jsonConfig | grep -ci metronome` -gt 0 ]] ; then
        mode=metronome
    fi
    if [[ $# -ge 3 ]] ; then
        mode=$3
    fi
    if [[ $mode = "metronome" ]]; then
        echo "Deploying a Scheduled jobs on metronome on host $mesosMaster"
        echo "curl -X POST http://$mesosMaster/service/metronome/v1/jobs -d @$jsonConfig -H 'Content-Type: application/json' "
        curl -X POST http://$mesosMaster/service/metronome/v1/jobs -d @$jsonConfig -H 'Content-Type: application/json'
    else
        echo "Deploying a long running service on marathon on host $mesosMaster"
        echo "curl -X POST http://$mesosMaster/marathon/v2/apps -d @$jsonConfig -H 'Content-type: application/json'"
        curl -X POST http://$mesosMaster/marathon/v2/apps -d @$jsonConfig -H 'Content-type: application/json'
    fi
}

unalias killSparkMesos 2>/dev/null
killSparkMesos() {
    mesosMaster=$1
    taskId=$2
    echo "spark-submit --deploy-mode cluster --master mesos://$mesosMaster/service/spark/ --conf spark.ssl.noCertVerification=true --verbose --kill $taskId"
    spark-submit --deploy-mode cluster --master mesos://$mesosMaster/service/spark/ --conf spark.ssl.noCertVerification=true --verbose --kill $taskId
}

unalias nodetoolCleanAllSnapshots 2>/dev/null
nodetoolCleanAllSnapshots() { 
    nodetool clearsnapshot $(nodetool listsnapshots | grep '-' | awk '{print $1}')
}

unalias esHealth 2>/dev/null
esHealth() {
    eshost=localhost
    esport=9200
    if [[ $# -ge 1 ]]; then eshost=$1 ; fi
    if [[ $# -ge 2 ]]; then esport=$2 ; fi
    echo "curl -X GET '${eshost}:${esport}/_cat/health?v'"
    curl -X GET "${eshost}:${esport}/_cat/health?v"
}

unalias esListIndices 2>/dev/null
esListIndices() {
    eshost=localhost
    esport=9200
    if [[ $# -ge 1 ]]; then eshost=$1 ; fi
    if [[ $# -ge 2 ]]; then esport=$2 ; fi
    echo "curl -X GET '${eshost}:${esport}/_cat/indices?v'"
    curl -X GET "${eshost}:${esport}/_cat/indices?v"
}

unalias esGetIndex 2>/dev/null
esGetIndex() {
    eshost=localhost
    esport=9200
    indexname=$1
    if [[ $# -ge 3 ]]; then eshost=$2 ; fi
    if [[ $# -ge 4 ]]; then esport=$3 ; fi
    #echo "curl -X GET '${eshost}:${esport}/${indexname}'"
    curl -X GET "${eshost}:${esport}/${indexname}"
}

unalias esPutIndex 2>/dev/null
esPutIndex() {
    eshost=localhost
    esport=9200
    indexname=$1
    body=$2
    if [[ $# -ge 3 ]]; then eshost=$3 ; fi
    if [[ $# -ge 4 ]]; then esport=$4 ; fi
    echo "curl -X PUT '${eshost}:${esport}/${indexname}?pretty' -d \'${body}\'"
    curl -X PUT "${eshost}:${esport}/${indexname}?pretty" -d "${body}"
}

unalias esPut 2>/dev/null
esPut() {
    eshost=localhost
    esport=9200
    indexname=$1
    typedoc=$2
    id=$3
    body=$4
    if [[ $# -ge 5 ]]; then eshost=$5 ; fi
    if [[ $# -ge 6 ]]; then esport=$6 ; fi
    echo "curl -X PUT '${eshost}:${esport}/${indexname}/${typedoc}/${id}?pretty' -d \'${body}\'"
    curl -X PUT "${eshost}:${esport}/${indexname}/${typedoc}/${id}?pretty" -d "${body}"
}

unalias esGet 2>/dev/null
esGet() {
    eshost=localhost
    esport=9200
    indexname=$1
    typedoc=$2
    id=$3
    if [[ $# -ge 4 ]]; then eshost=$4 ; fi
    if [[ $# -ge 5 ]]; then esport=$5 ; fi
    echo "curl -X GET '${eshost}:${esport}/${indexname}/${typedoc}/${id}?pretty'"
    curl -X GET "${eshost}:${esport}/${indexname}/${typedoc}/${id}?pretty"
}

unalias esSearchAll 2>/dev/null
esSearchAll() {
    eshost=localhost
    esport=9200
    indexname=$1
    if [[ $# -ge 2 ]]; then eshost=$2 ; fi
    if [[ $# -ge 3 ]]; then esport=$3 ; fi
    echo "curl -X POST '${eshost}:${esport}/${indexname}/_search?q=*&pretty'"
    curl -X POST "${eshost}:${esport}/${indexname}/_search?q=*&pretty"
}

unalias esSearch 2>/dev/null
esSearch() {
    eshost=localhost
    esport=9200
    indexname=$1
    body=$2
    if [[ $# -ge 3 ]]; then eshost=$3 ; fi
    if [[ $# -ge 4 ]]; then esport=$4 ; fi
    echo "curl -X POST '${eshost}:${esport}/${indexname}/_search?pretty' -d \'${body}\'"
    curl -X POST "${eshost}:${esport}/${indexname}/_search?pretty" -d "${body}"
}

unalias esSearchId 2>/dev/null
esSearchId() {
    eshost=localhost
    esport=9200
    indexname=$1
    id=$2
    if [[ $# -ge 3 ]]; then eshost=$3 ; fi
    if [[ $# -ge 4 ]]; then esport=$4 ; fi
    echo "curl -X POST '${eshost}:${esport}/${indexname}/_search?pretty' -d '{ \"query\": { \"match\": { \"_id\": \"${id}\" } } }'"
    curl -X POST "${eshost}:${esport}/${indexname}/_search?pretty" -d '{ "query": { "match": { "_id": "'${id}'" } } }'
}

unalias checkEncoding 2>/dev/null
checkEncoding() {
    #listencoding="ASCII ISO-8859-2 ISO-8859-4 ISO-8859-5 ISO-8859-13 ISO-8859-16 CP1125 CP1250 CP1251 CP1257 IBM852 IBM855 IBM775 IBM866 baltic KEYBCS2 macce maccyr ECMA-113 KOI-8_CS_2 KOI8-R KOI8-U KOI8-UNI TeX UCS-2 UCS-4 UTF-7 UTF-8 CORK GBK BIG5 HZ unknown"
    listencoding=`iconv -l 2>/dev/null | tr -d "//"`
    inputfile=$1
    for charset in $listencoding; do 
        echo "         iconv -f $charset -t UTF-8 $inputfile"
        iconv -f $charset -t UTF-8 $inputfile 2>/dev/null
    done
}

unalias zkInit 2>/dev/null
zkInit()
{
    exporte ZOOKEEPER_HOME=/opt/apache-zookeeper
    exporte ZOOKEEPER_HOME=/opt/zookeeper
    exporte ZOOBINDIR=$ZOOKEEPER_HOME/bin
    echo "zkServer.sh start $ZOOKEEPER_HOME/conf/zoo.cfg"
}

unalias hadoopInit 2>/dev/null
hadoopInit()
{
    exporte HADOOP_HOME=/opt/apache-hadoop
    exporte HADOOP_HOME=/opt/hadoop
    exporte HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
    if [[ -e ${HADOOP_CONF_DIR} ]]; then
        . $HADOOP_CONF_DIR/hadoop-env.sh
        exporte LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
        exporte PATH=$PATH:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
    fi
    echo "start-dfs.sh"
    echo "start-yarn.sh"
    echo "start-hbase.sh start"
}

unalias sparkInit 2>/dev/null
sparkInit()
{
    exporte SPARK_HOME=/opt/apache-spark
    exporte SPARK_HOME=/opt/spark
    exporte PATH=$PATH:${SPARK_HOME}/bin
}

unalias cpuPower 2>/dev/null
cpuPower()
{
    for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f $CPUFREQ ] || continue; sudo sh -c "echo -n powersave > $CPUFREQ"; done
}

unalias cpuPerf 2>/dev/null
cpuPerf()
{
    for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do [ -f $CPUFREQ ] || continue; sudo sh -c "echo -n performance > $CPUFREQ"; done
}

unalias kgetport 2>/dev/null
kgetport()
{
    kubectl get svc $1 -o=jsonpath="{.spec.ports[?(@.port==$2)].nodePort}"
}

unalias klsport 2>/dev/null
klsport()
{
    kubectl get svc --all-namespaces -o go-template='{{range .items}}{{ $save := . }}{{range.spec.ports}}{{if .nodePort}}{{$save.metadata.namespace}}{{"/"}}{{$save.metadata.name}}{{" - "}}{{.name}}{{": "}}{{.targetPort}}{{" -> "}}{{.nodePort}}{{"\n"}}{{end}}{{end}}{{end}}'
}

# Modifies the configuration of a node in the CCM cluster.
function ccm_update_node_config {
    if [[ $# -eq 2 ]] ; then
        nodeint=$1
        newdc=$2
        if [[ -z ${CLUSTER_NAME} ]]; then
            CLUSTER_NAME=test
        fi
        CASSANDRA_YAML_SETTINGS="authenticator:PasswordAuthenticator \
                          network_authorizer:CassandraNetworkAuthorizer \
                          num_tokens:256 \
                          endpoint_snitch:GossipingPropertyFileSnitch \
                          seeds:127.0.0.1"

        # CASSANDRA_YAML_SETTINGS="endpoint_snitch:GossipingPropertyFileSnitch \
        #                   seeds:127.0.0.1,127.0.0.4"

        for key_value_setting in ${CASSANDRA_YAML_SETTINGS}
        do
            setting_key=$(echo ${key_value_setting} | cut -d':' -f1)
            setting_val=$(echo ${key_value_setting} | cut -d':' -f2)
            sed -ie "s/${setting_key}\:\ .*/${setting_key}:\ ${setting_val}/g" \
                ~/.ccm/${CLUSTER_NAME}/node${nodeint}/conf/cassandra.yaml
        done

        sed -ie "s/dc=.*/dc=${newdc}/g" \
            ~/.ccm/${CLUSTER_NAME}/node${nodeint}/conf/cassandra-rackdc.properties
        #sed -ie 's/\#MAX_HEAP_SIZE=\"4G\"/MAX_HEAP_SIZE=\"1G\"/g' \
            #  ~/.ccm/${CLUSTER_NAME}/node${1}/conf/cassandra-env.sh
        #sed -ie 's/\#HEAP_NEWSIZE=\"800M\"/HEAP_NEWSIZE=\"250M\"/g' \
            #  ~/.ccm/${CLUSTER_NAME}/node${1}/conf/cassandra-env.sh
    fi
}

unalias cassandraInit 2>/dev/null
cassandraInit()
{
    export CASSANDRA_VERSION=3.11.5
    exporte CASSANDRA_HOME=/opt/apache-cassandra-${CASSANDRA_VERSION}
    exporte CASSANDRA_HOME=/opt/cassandra
    if [[ -e ${CASSANDRA_HOME} ]]; then
        exporte CASSANDRA_CONF=${CASSANDRA_HOME}/conf
        exporte CASSANDRA_LOG_DIR=/var/log/cassandra-${CASSANDRA_VERSION}
        exporte PATH=$PATH:${CASSANDRA_HOME}/bin
        exporte PATH=$PATH:${CASSANDRA_HOME}/tools/bin
        . ${CASSANDRA_HOME}/bin/cassandra.in.sh
        alias nt=${CASSANDRA_HOME}/bin/nodetool
    fi
    echo "You can start C* with : $CASSANDRA_HOME/bin/cassandra -f"
}

unalias sstableCopy 2>/dev/null
sstableCopy()
{

    # arg1: source sstable filename 
    # arg2: destination path
    # usage: sstableCopy lb-9-big-CompressionInfo.db /tmp
    # From a source sstable filename retrieve all linked cassandra files and 
    # copy them to the destination.
    # avoid naming collision between source and destination by incrementing sstable ID number if necessary

    src=$1
    dest=$2
    if [[ $# -ne 2 ]]; then
        echo "ERROR ! need 2 args"
    elif [[ ! -e ${src} ]]; then
        echo "ERROR ! File not found ${src} !"
    elif [[ -d ${src} ]]; then
        echo "ERROR ! Directory given in input instead of a file :  ${src} !"
    elif [[ ! -d ${dest} || -z ${dest} ]]; then
        echo "ERROR ! Directory given in input not found :  ${dest} !"
    else
        srcfile=`basename ${src}`
        srcdir=`dirname ${src}`
        suffix=`echo ${srcfile} | awk -F "-" '{ print $NF}'`
        prefix=${srcfile%%$suffix}
        filelist=`ls $(dirname ${src})/${prefix}*`
        toberenamed=0
        if [[ ! -z `ls ${dest}/${prefix}* 2>/dev/null` ]] ; then
            echo "Warning : file already exists, ID number will be incremented before copy"
            toberenamed=1
        fi
        if [[ ${toberenamed} -eq 0 ]]; then
            for filewithpath in ${filelist} ; do
                echo ${filewithpath} ${dest}/
                cp ${filewithpath} ${dest}/
            done
        else
            lastnumber=`ls ${srcdir}/*.db ${dest}/*.db | awk -F "-" '{ print $2 }' | sort -n |tail -1`
            newnumber=$((${lastnumber}+1))
            for filewithpath in ${filelist} ; do
                f=`basename ${filewithpath}`
                if [[ `echo ${f} | grep -o "-" | wc -l` -ne 3 ]] ; then
                    echo "Error naming not supported : $f \n should be like lb-3-big-Data.db"
                else
                    pre=`echo ${f} | awk -F "-" '{ print $1}'`
                    suf=`echo ${f} | awk -F "-" '{ print $3}'`
                    echo ${filewithpath} ${dest}/${pre}-${newnumber}-${suf}-`echo ${f} | awk -F "-" '{ print $NF}'`
                    cp ${filewithpath} ${dest}/${pre}-${newnumber}-${suf}-`echo ${f} | awk -F "-" '{ print $NF}'`
                fi
            done
        fi
    fi
}

unalias cassandraCleanStress 2>/dev/null
cassandraCleanStress() {
    export ks=tlp_stress
    listTable=`cqlsh $HOST -e "USE ${ks}; DESC tables;" | grep -v -e '^[[:space:]]*$'`
    for table in $listTable ; do
        cqlsh $HOST -e "USE ${ks}; TRUNCATE TABLE ${table};" 
    done
    sleep 10
    sudo systemctl stop cassandra
    if [[ ! -z ${CASSANDRA_LOG_DIR} ]]; then
       sudo rm -f ${CASSANDRA_LOG_DIR}/*.log*
    fi
    sudo systemctl start cassandra
}

unalias bash_prompt_shortener 2>/dev/null
bash_prompt_shortener() {
    # How many characters of the $PWD should be kept
    local pwdmaxlen=50
    # Indicate that there has been dir truncation
    local trunc_symbol=".."
    local dir=${PWD##*/}
    pwdmaxlen=$(( ( pwdmaxlen < ${#dir} ) ? ${#dir} : pwdmaxlen ))
    NEW_PWD=${PWD/#$HOME/\~}
    local pwdoffset=$(( ${#NEW_PWD} - pwdmaxlen ))
    if [ ${pwdoffset} -gt "0" ]
    then
        NEW_PWD=${NEW_PWD:$pwdoffset:$pwdmaxlen}
        NEW_PWD=${trunc_symbol}/${NEW_PWD#*/}
    fi
}

function kusage() {
    # Function returning resources usage on current kubernetes cluster
        local node_count=0
        local total_percent_cpu=0
        local total_percent_mem=0

    echo "NODE\t\t CPU_allocatable\t Memory_allocatable\t CPU_requests%\t Memory_requests%\t CPU_limits%\t Memory_limits%\t"
        for n in $(kubectl get nodes --no-headers -o custom-columns=NAME:.metadata.name); do
        local desc=$(kubectl describe node $n)
        local abs_cpu=$(echo $desc | grep -A5 -E "Resource" | grep -E "cpu" | tr -d '(%)'| awk '{print $2}')
                local percent_cpu=$(echo $desc | grep -A5 -E "Resource" | grep -E "cpu" | tr -d '(%)'| awk '{print $3}')
        local node_cpu=$(echo $desc | grep -A5 -E "Allocatable:" | grep -E "cpu" | tr -d '(%)'| awk '{print $2}')
        local allocatable_cpu=$(echo $node_cpu $abs_cpu | tr -d 'mKi' | awk '{print int($1 - $2)}')
        local percent_cpu_lim=$(echo $desc | grep -A5 -E "Resource" | grep -E "cpu" | tr -d '(%)'| awk '{print $5}')
        local abs_mem=$(echo $desc | grep -A5 -E "Resource" | grep -E "memory" | tr -d '(%)'| awk '{print $2}')
                local percent_mem=$(echo $desc | grep -A5 -E "Resource" | grep -E "memory" | tr -d '(%)'| awk '{print $3}')
        local node_mem=$(echo $desc | grep -A5 -E "Capacity:" | grep -E "memory" | tr -d '(%)'| awk '{print $2}')
        local allocatable_mem=$(echo $node_mem $abs_mem | tr -d 'mKi' | awk '{print int($1 - $2)}')
        local percent_mem_lim=$(echo $desc | grep -A5 -E "Resource" | grep -E "memory" | tr -d '(%)'| awk '{print $5}')
                echo "$n\t $((${allocatable_cpu}/1000))\t\t\t $((${allocatable_mem}/1024/1024))Gi\t\t\t ${percent_cpu}%\t\t ${percent_mem}%\t\t\t ${percent_cpu_lim}%\t\t ${percent_mem_lim}%\t"

                node_count=$((node_count + 1))
                total_percent_cpu=$((total_percent_cpu + percent_cpu))
                total_percent_mem=$((total_percent_mem + percent_mem))
        done

        local avg_percent_cpu=$((total_percent_cpu / node_count))
        local avg_percent_mem=$((total_percent_mem / node_count))

        echo "Average usage (requests) : ${avg_percent_cpu}% CPU, ${avg_percent_mem}% memory."
}                                                                                                                                                                                                                                                                                

unalias mycolor 2>/dev/null
mycolor () {
    if [ -z "$1" -a -z "$2" -a -z "$3" ]; then
        echo "\033[0m"
        return
    fi
    case $1 in
#        black)   color_fg=30;;
        red|1|0)     color_fg=31;;
        green|2)   color_fg=32;;
        yellow|3|8)  color_fg=33;;
        4)    color_fg=38;;
        blue|3|8)    color_fg=34;;
        magenta|purple|7|5) color_fg=35;;
        cyan|6)    color_fg=36;;
        white|7)   color_fg=37;;
        -)       color_fg='';;
        *|9)       color_fg=39;;
    esac
    case $2 in
        bold)      color_bd=1;;
        italics)   color_bd=3;;
        underline) color_bd=4;;
        inverse)   color_bd=7;;
        strike)    color_bd=9;;
        nobold)      color_bd=22;;
        noitalics)   color_bd=23;;
        nounderline) color_bd=24;;
        noinverse)   color_bd=27;;
        nostrike)    color_bd=29;;
        -)         color_bd='';;
        *)         color_bd=0
    esac
    case $3 in
        black)   color_bg=40;;
        red|1|0)     color_bg=41;;
        green|2)   color_bg=42;;
        yellow|3)  color_bg=43;;
        blue|4)    color_bg=44;;
        magenta|purple|5) color_bg=45;;
        cyan|6)    color_bg=46;;
        white|7)   color_bg=47;;
        lightgray|8)   color_bg=100;;
        # darkgray|9)   color_bg="\e[48;5;238";;
        # darkblue|10)   color_bg="\e[48;5;17";;
        # lightgreen|11)   color_bg="\e[48;5;193";;
        # lightcyan|12)   color_bg="\e[48;5;193";;
        # darkred|13)   color_bg="\e[48;5;88";;
        # lightpurple|14)   color_bg="\e[48;5;129";;
        # lightyellow|15)   color_bg="\e[48;5;228";;
        -)       color_bg='';;
        *)       color_bg=49;;
    esac

    if [[ ${color_fg} -eq $((${color_bg}-10)) ]]; then
        color_bg=$((${color_bg}+1))
    fi
    #echo $color_bg $color_bd $color_bg
    s='\033['
    if [ -n "$color_bd" ]; then
        s="${s}${color_bd}"
        if [ -n "$color_fg" -o -n "$color_bg" ]; then
            s="${s};"
        fi
    fi
    if [ -n "$color_fg" ]; then
        s="${s}${color_fg}"
        if [ -n "$color_bg" ]; then
            s="${s};"
        fi
    fi
    if [ -n "$color_bg" ]; then
        s="${s}${color_bg}"
    fi
    s="${s}m"
    echo "$s"
    unset s color_bd color_bg color_fg
}

unalias mypromptcolor 2>/dev/null
mypromptcolor () {
    export iuser=`echo $USER | md5sum | awk '{print $1}' | tr -d "[a-z]" | tr -d "[A-Z]"  | cut -c 3-3`
    export ihost=`echo $HOSTNAME | md5sum | awk '{print $1}' | tr -d "[a-z]" | tr -d "[A-Z]" | tr -d "$iuser" | cut -c 3-3`
    export iprompt=`echo $USER@$HOSTNAME | md5sum | awk '{print $1}' | tr -d "[a-z]" | tr -d "[A-Z]" | tr -d "$iuser" | tr -d "$ihost" | cut -c 3-3`
    # Black       0;30     Dark Gray     1;30
    # Blue        0;34     Light Blue    1;34
    # Green       0;32     Light Green   1;32
    # Cyan        0;36     Light Cyan    1;36
    # Red         0;31     Light Red     1;31
    # Purple      0;35     Light Purple  1;35
    # Brown       0;33     Yellow        1;33
    # Light Gray  0;37     White         1;37
    # standard colors Background
    #for C in {40..47}; do     echo -en "\e[${C}m$C "; done; echo ''
    # high intensity colors Background
    #for C in {100..107}; do     echo -en "\e[${C}m$C "; done; echo ''
    # 256 colors Background
    #for C in {16..255}; do     echo -en "\e[48;5;${C}m$C "; done; echo ''
    # standard colors Foreground
    #for C in {30..37}; do     echo -en "\e[${C}m$C "; done; echo ''
    # high intensity colors Foreground
    #for C in {90..97}; do     echo -en "\e[${C}m$C "; done; echo ''
    #export PS1="\033[31m\w/\e[1;37m\n[\u@\H]\$ "

    bash_prompt_shortener
    color_std=`mycolor black bold white`
    #color_std=`mycolor white bold black`
    color_reset=$(tput -T xterm-256color sgr0)
    if [[ $user = "root" ]]; then
        color_host=`mycolor white bold red`
        color_user=`mycolor white bold red`
        color_path=`mycolor red bold $ihost`
    else
        color_host=`mycolor $ihost bold white`
        color_user=`mycolor $iuser bold black`
        color_path=`mycolor $iprompt bold $ihost`
    fi
    export PS1="\[${color_path}\]\w/\[${color_reset}\]\n\[${color_user}\][\u\[${color_reset}\]@\[${color_host}\]\H]\[${color_reset}\]> "
    #export PS1="epoch=\D{%s}  \[${color_path}\]\w/\[${color_reset}\]\n\[${color_user}\][\u\[${color_reset}\]@\[${color_host}\]\H]\[${color_reset}\]> "
    export PS2="\[${color_reset}\]\w/\[${color_reset}\]\n\[${color_reset}\][\u\[${color_reset}\]@\[${color_reset}\]\H]\[${color_reset}\]> "
}

unalias myprompt 2>/dev/null
myprompt() {
    if [[ $# -eq 2 ]] ; then
        foregroud=$1
        background=$2
        color_std=`mycolor $foregroud bold $background`
        color_user=`mycolor $foregroud bold $background`
        color_path=`mycolor $foregroud bold $background`
        color_host=`mycolor $foregroud bold $background`
        color_reset=$(tput -T xterm-256color sgr0)
        export PS1="\[${color_path}\]\w/\[${color_reset}\]\n\[${color_user}\][\u\[${color_reset}\]@\[${color_host}\]\H]\[${color_reset}\]> "
    elif [[ $# -eq 1 ]] ; then
        foregroud=$1
        background=white
        color_std=`mycolor $foregroud bold $background`
        color_user=`mycolor $foregroud bold $background`
        color_path=`mycolor $foregroud bold $background`
        color_host=`mycolor $foregroud bold $background`
        color_reset=$(tput -T xterm-256color sgr0)
        export PS1="\[${color_path}\]\w/\[${color_reset}\]\n\[${color_user}\][\u\[${color_reset}\]@\[${color_host}\]\H]\[${color_reset}\]> "
    else
        echo "ERROR need two inputs: foreground color and background color"
        echo "example: myprompt white black"
    fi
}

unalias setail 2>/dev/null
setail()
{
    tail /var/log/audit/audit.log | ausearch -i
}

unalias envSsh 2>/dev/null
envSsh()
{
    if [[ $# -eq 0 ]] ; then
        list=$mylistSsh
    else
        list=$@
    fi
    echo $list
    for dest in $list ; do
        echo "rsync -e 'ssh' -rtvc $HOME/.bashrc $dest:"
        rsync -e "ssh" -rtvc $HOME/.bashrc $HOME/.emacs* $dest: 
    done
}

mntaz() {
    if [[ $# -ge 2 ]] ; then
        echo "sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$1,password=$2,dir_mode=0777,file_mode=0777"
        sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$1,password=$2,dir_mode=0777,file_mode=0777
    else
        echo "sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$1,dir_mode=0777,file_mode=0777"
        sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$1,dir_mode=0777,file_mode=0777
    fi
    username=$user 
    if [[ $# -ge 1 ]] ; then
        username=$1
    fi
    if [[ $# -ge 2 ]] ; then
        echo "sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$username,password=$2,dir_mode=0777,file_mode=0777"
        sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$username,password=$2,dir_mode=0777,file_mode=0777
    else
        echo "sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$username,dir_mode=0777,file_mode=0777"
        sudo mount -t cifs //myblob.blob.core.windows.net/vhds /mnt/myblob -o vers=3.0,username=$username,dir_mode=0777,file_mode=0777
    fi
}

unalias rmtCheckMem 2>/dev/null
rmtCheckMem() {
    if [[ $# -eq 0 ]]; then
        echo "*/ list of hosts"
    fi
    list=$mylistSsh
    if [[ $# -ge 1 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        echo "==================================================================================="
        echo "ssh $dest 'ps aux --sort rss | tail -6 ; hostname -f ;free -m'"
        ssh $dest 'ps aux --sort rss | tail -6 ; hostname -f ; free -m'
        #ssh $dest 'ps aux --sort rss | tail -6 ; hostname -f ; vmstat -s -S m'
    done
}

unalias sudocheck 2>/dev/null
sudocheck() {
    timeout -s 9 1 sudo echo 'sudo OK'
    if [[ $? -ne 0 ]]; then echo 'ERROR'; fi
}

unalias clearcache 2>/dev/null
clearcache() {
    # Clear PageCache only.
    # needs root perm
    timeout -s 9 90 sudo -- bash -c 'sync; echo 1 > /proc/sys/vm/drop_caches'
    # if [[ $? -ne 0 ]]; then echo 'ERROR during clearcache'; exit 9; fi
}

unalias rmtCheckJournal 2>/dev/null
rmtCheckJournal() {
    if [[ $# -eq 0 ]]; then
        echo "1/ number of days to take into account in history"
        echo "*/ list of hosts"
    fi
    sinceDays=1
    list=$mylistSsh
    if [[ $# -ge 1 ]]; then
        sinceDays=$1
    fi
    if [[ $# -ge 2 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        if [[ "$dest" != "$sinceDays" ]]; then
            echo "==================================================================================="
            echo "ssh $dest \"journalctl -b -q -p 0..4 -x -r --since=-$sinceDays\d\""
            ssh $dest "journalctl -b -q -p 0..4 -x -r --since=-$sinceDays\d"
        fi
    done
}

unalias rmtCheckDcosJournal 2>/dev/null
rmtCheckDcosJournal() {
    if [[ $# -eq 0 ]]; then
        echo "1/ number of days to take into account in history"
        echo "*/ list of hosts"
    else
        sinceDays=1
        list=$(echo $mylistSsh | grep dcos)
        if [[ $# -ge 1 ]]; then
            sinceDays=$1
        fi
        if [[ $# -ge 2 ]]; then
            list=$@
        fi
        echo $list
        for dest in $list; do
            if [[ "$dest" != "$sinceDays" ]]; then
                echo "==================================================================================="
                echo "ssh $dest \"find /var/lib/mesos/slave \""
                ssh $dest ". /etc/profile ; find /var/lib/mesos/slave \( -name stderr -print  -o -name stdout -print \) -mtime -$sinceDays 2>/dev/null | xargs grep -e '^ERROR' -e '^java.lang.' -e ' ERROR ' -e '^java.io' -e 'Exception' -e 'error' -e '\[ERROR\]'"
            fi
        done
    fi
}

unalias rmtCheckDcosUp 2>/dev/null
rmtCheckDcosUp() {
    if [[ $# -eq 0 ]]; then
        echo "1/ number of days to take into account in history"
        echo "*/ list of hosts"
    fi
    list=$mylistSshDcos
    if [[ $# -ge 1 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        echo "==================================================================================="
        echo "ssh $dest \"systemctl status dcos-mesos-slave.service dcos-mesos-master.service\""
        ssh $dest ". /etc/profile ; /sbin/ifconfig eth0 | grep 'inet ' | sed s/'addr://g' | awk '{print $2}' ; systemctl status dcos-mesos-slave.service dcos-mesos-master.service | grep 'Active:'"
    done
}

unalias rmtCheckDocker 2>/dev/null
rmtCheckDocker() {
    if [[ $# -eq 0 ]]; then
        echo "1/ number of days to take into account in history"
        echo "*/ list of hosts"
    fi
    list=$mylistSshDcos
    if [[ $# -ge 1 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        echo "==================================================================================="
        echo "ssh $dest docker ps"
        ssh $dest ". /etc/profile ; docker ps --no-trunc "
    done
}

unalias rmtCheckDcosTasks 2>/dev/null
rmtCheckDcosTasks() {
    if [[ $# -eq 0 ]]; then
        echo "1/ number of days to take into account in history"
        echo "*/ list of hosts"
    fi
    list=$mylistSshDcos
    if [[ $# -ge 1 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        echo "==================================================================================="
        echo "ssh $dest ls -lrtd /var/lib/mesos/slave/slaves/*/frameworks/*/executors/*"
        ssh $dest ". /etc/profile ; ls -lrt /var/lib/mesos/slave/slaves/*/frameworks/*/executors/*"
    done
}

unalias rmtKillJava 2>/dev/null
rmtKillJava() {
    if [[ $# -eq 0 ]]; then
        echo "1/ name of the java app"
        echo "*/ list of hosts"
    fi
    list=x.x.x.x
    appname=hdfs
    if [[ $# -ge 1 ]]; then
        appname=$1
    fi
    if [[ $# -ge 2 ]]; then
        list=$@
    fi
    echo $list
    for dest in $list; do
        if [[ "$dest" != "$appname" ]]; then
            echo "==================================================================================="
            echo "ssh $dest \"ps -ef | grep java | grep -v grep | grep $appname | awk '{print \$2}' | xargs sudo kill -9\""
            ssh $dest "ps -ef | grep java | grep $appname | awk '{print \$2}' | xargs sudo kill -9"
        fi
    done
}

unalias snapCleanup 2>/dev/null
snapCleanup() {
    echo "snapCleanup"
    sudo snap list --all | awk '/disabled/{print $1, $3}' |
        while read snapname revision; do
            sudo snap remove "$snapname" --revision="$revision"
        done
}

unalias snapDisable 2>/dev/null
snapDisable() {
    echo "snapDisable"
    snap list --all
    snap list --all | awk '{print $1}' |
        while read snapname revision; do
            snap remove "$snapname"
        done
    snap list --all | awk '{print $1}' |
        while read snapname revision; do
            snap remove "$snapname"
        done
    snap list --all
    apt purge -y snapd
    rm -rf /snap
    rm -rf /var/snap
    rm -rf /var/lib/snapd
    rm -rf /home/*/snap
    rm -rf /root/snap
}

unalias btrfsCleanup 2>/dev/null
btrfsCleanup() {
    sudo btrfs subvolume list /
    sudo snapCleanup
    echo "btrfsCleanup"
    sudo apt-btrfs-snapshot delete-older-than 0d
    sudo btrfs fi show
    sudo btrfs fi df /
    sudo btrfs fi usage /
    sudo btrfs balance start -dusage=80 /
    sudo btrfs scrub start -d /
    sleep 120
    sudo btrfs fi df /var
    sudo btrfs fi usage /var
    sudo btrfs balance start -dusage=80 /var
    sudo btrfs scrub start -d /var
    sleep 120
    sudo btrfs fi df /var
    sudo btrfs fi usage /var
    echo "Done"
}

unalias hll 2>/dev/null
hll() {
    hdfs dfs -ls $@ |grep -v '^Found'
}

unalias hls 2>/dev/null
hls() {
    hdfs dfs -ls $@ |grep -v '^Found' | awk '{print $NF}'
}

unalias hrm 2>/dev/null
hrm() {
    hdfs dfs -rm $@
}

unalias hcploc 2>/dev/null
hcploc() {
    hdfs dfs -copyToLocal $@
}

unalias hschema 2>/dev/null
hschema() {
    hadoop jar /opt/tools/latest/depjars/parquet-tools-1.9.0.jar schema $@
}

unalias hcat 2>/dev/null
hcat() {
    hadoop jar /opt/tools/latest/depjars/parquet-tools-1.9.0.jar cat $@
}

unalias lssocket 2>/dev/null
lssocket() {
    if [[ ! -z `which ss 2>/dev/null` ]] ; then
        ss -natpu -4
    else
        netstat -natpu -4
    fi
}

unalias lsport 2>/dev/null
lsport() {
    nmap -v -O --version-intensity 2 --host-timeout 30s -p- -sV $1
}

unalias virshstop 2>/dev/null
virshstop() {
    for v in `virsh list --all | grep running | awk '{print $2}'` ;do virsh shutdown $v; done
}
 
unalias kernelpurge 2>/dev/null
kernelpurge() {
    uname -a
    current_ver=$(uname -a | awk '{ print $3 }')
    echo "Your in use kernel is $current_ver"

    OLD_KERNELS=$(
        dpkg --list |
            grep -v "$current_ver" |
            grep -Ei 'linux-image|linux-headers|linux-modules|nvidia' |
            awk '{ print $2 }'
               )
    echo "Old Kernels to be removed WARNING double check nvidia !!!"
    echo "$OLD_KERNELS"
    
    sudo apt-get autoremove --purge
    # if [ "$1" == "exec" ]; then
    #     for PACKAGE in $OLD_KERNELS; do
    #         sudo apt purge -y "$PACKAGE"
    #     done
    # fi
}

#------------------------------------------------------------------------------
##echo "Source .kshrc"
export tmpstr=tmp_$USER\_$(date '+%y%m%d')_$(date '+%H%M%S')
idir=$(pwd)

########
#PROMPT#
########
if [[ -z $force_color_prompt ]] ; then
    force_color_prompt=yes
fi
if [[ ($SHELL = 'bash' || "$(echo $myshell | grep 'bash')" != "") && $force_color_prompt != "no" ]]; then
    mypromptcolor
else
    export PS1="\w/\n[\u@\H]> "
fi

#------------------------------------------------------------------------------
# Alias
#
if [[ $(uname -s) = "Linux" ]] ; then
    alias ls='ls --color=never'
    alias l='ls --color'
    alias ll='ls --color -lah'
    alias lll='ls --color -lahi'
    alias lt='ls --color -larth'
    alias ggrep='grep -r --color --binary-files=without-match --no-message'
    #alias ggrep='find . -name "*target*" -prune -o -type f -print 2>/dev/null | grep -v -e "/.idea" -e "/.git" | xargs grep --color --binary-files=without-match --no-message '
    alias lscg="ls -l /proc/*/cgroup | awk '{if ($5 != 0) print $9}'"
    #lsns list all namespaces
    alias lsn="readlink /proc/*/task/*/ns/* | sort -u"
else
    alias l='ls'
    alias ll='ls -la'
    alias lt='ls -lart'
    alias ggrep='find ./ \( -name ".*" -prune -o -print \) 2>/dev/null | xargs grep -s '    
    alias rgrep='find . 2>/dev/null | xargs grep -s'
fi
if [[ ! -z `which exa 2>/dev/null` ]] ; then
    alias l="exa -a1" # short for "1"line "A"ll
    # alias ls="exa -F" # with suffixes (/ for dirs, ect.)
    # alias ll="exa -aFl --git" # full
    alias ll="exa -algF " # full with hidden files
    alias lt="exa -algF --sort modified" # full with hidden files
    # alias lt="exa -a --tree" # tree
    # alias lt1="exa -a --tree -L1" # tree level 1
    # alias lt2="exa -a --tree -L2" # tree level 2
    alias llt="exa -a --tree" # long tree
    alias llt1="exa -a --tree -L1" # long tree level 1
    alias llt2="exa -a --tree -L2" # long tree level 2
    alias lr="exa -R" # recurse
fi
alias safeRm="echo 'WARNING ! shreding the cwd'; sleep 10; find . type f -exec shred -vzn 0 {} \;"
alias e='emacs'
alias dirs="dirs -v"
alias pd=pushd
alias lsdr="find . -type d"
alias lsdl="\ls -lrt | awk '/^d/ { f=\$NF }; END{ print f }' "
alias cdl="cd \$(\ls -lrt | awk '/^d/ { f=\$NF }; END{ print f }') "
alias rsyncbk="rysnc -rlptDzP"
alias rsyncupd="rysnc -rlptDcuP"
alias hh='history'
alias rmtt="rm -f *~"
alias rmpt="rm -f .*~"
alias psu="ps -f -u $USER"
alias topu="top -U $USER"
alias dmesg="dmesg -TL"
alias nt="time nodetool"
alias dstat="\dstat -tcndylpm --top-cpu"
# keep always alive a ssh connection without crap on terminal
alias kup='(while true ; do echo -ne "\000" ; sleep 600 ; done ) &'
alias rsynci="rsync -e 'ssh -i $HOME/.ssh/jlu_aws.pem'"
alias journalcheck="journalctl -b -q -p 0..4 -x"
alias dockerrm="docker rm -v \$(docker ps -a -q -f status=exited)"
#
alias envretrieve="rsync -tvc $scriptsdir/.bashrc $HOME/ && rsync -tvc $scriptsdir/.gitconfig $HOME/ && rsync -tvc $scriptsdir/.emacs $HOME/ && rsync -rtvc $scriptsdir/.emacs.d $HOME/ "
alias envbackup="rsync -rtvc $HOME/.bashrc $HOME/.gitconfig $HOME/.emacs $HOME/.emacs.d $scriptsdir/ && chmod -R go+rX $scriptsdir"
#
alias hrm="hdfs dfs -rm"
alias hcp="hdfs dfs -cp"
alias hmv="hdfs dfs -mv"
alias hschema="hadoop jar /opt/tools/latest/depjars/parquet-tools-1.9.0.jar schema"
alias kc=kubectl
alias ka=kubeadm
alias k=kubectl
alias kubectx="kubectl ctx"
alias kk="kubectl -n \$SPARK_KUBE_NS"
# for spark-submit vanilla
alias sparkclean="kk get pods --field-selector=status.phase!=Running | awk '{print \$1}' | grep -v '^NAME$' | xargs kubectl delete pods -n \${SPARK_KUBE_NS}"
alias sparklogs="kk logs"
alias sparkls="kk get pods -l=spark-app-name"
alias sparkll="kk get pods -l=spark-app-name -o 'custom-columns=NAMESPACE:.metadata.namespace,Name:.metadata.name,PHASE:.status.phase,RESTARTS:RESTART:.status.containerStatuses[0].restartCount,CREATED:.metadata.creationTimestamp,IPS:status.podIPs,NODE:.spec.nodeName,IMAGE:.spec.containers[0].image,LABELS:.metadata.labels'"
# for spark-operator
alias sls="kk get sparkapp"
alias sw="watch -c -n 5 kubectl get sparkapp -n \${SPARK_KUBE_NS}"
alias srm="kk delete sparkapp"
alias sclean="kk get sparkapp | grep -e ' COMPLETED ' -e ' FAILED ' | awk '{print \$1}' | grep -v '^NAME$' | xargs kubectl delete sparkapp -n \${SPARK_KUBE_NS}"

alias kdesc="kubectl describe nodes | grep --color=never -e '  cpu ' -e '  memory ' -e 'Name: ' -e 'worker-pool-name' -e 'node.kubernetes.io/instance-type' -e 'topology.kubernetes.io/zone'"
alias kallocated='kubectl get nodes --no-headers | awk '\''{print $1}'\'' | xargs -I {} sh -c '\''echo   {} ; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo '\'''
alias kcpualloc='kallocated | grep cpu | awk '\''{print $2}'\'' | tr -d "(%)" | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*2000), "%\n" } }'\'''
alias kmemalloc='kallocated | grep memory | awk '\''{print $2}'\'' | tr -d "(%)" | awk '\''{ sum += $1 } END { if (NR > 0) { print sum/(NR*75*1024*1024), "%\n" } }'\'''
alias knodes='kubectl get nodes -o custom-columns=IP:.metadata.name,ZONE:".metadata.labels.ibm-cloud\.kubernetes\.io/zone",FLAVOR:".metadata.labels.ibm-cloud\.kubernetes\.io/machine-type,POOL:.metadata.labels.ibm-cloud\.kubernetes\.io/worker-pool-name"'
alias kevents="kubectl get events --field-selector involvedObject.kind=Node --sort-by='.lastTimestamp'"
alias kpods="kubectl get pod -o=custom-columns=NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName --all-namespaces"
alias kpvcs="kubectl get pods --all-namespaces -o=json | jq -c '.items[] | {pod: .metadata.name, namespace: .metadata.namespace, status: .status.phase, node: .spec.nodeName, pvc: .spec |  select( has (\"volumes\") ).volumes[] | select( has (\"persistentVolumeClaim\") ).persistentVolumeClaim.claimName }'"

alias alarm="vlc ~/alarm.mp3"
#------------------------------------------------------------------------------
# Export
#
exporte KUBECONFIG=$KUBECONFIG:$HOME/.kube/config

if [[ ! -z $(which sublime 2>/dev/null) ]] ; then
    export EDITOR=sublime
elif [[ ! -z $(which emacs 2>/dev/null) ]] ; then
    export EDITOR=emacs
else
    export EDITOR=vi
fi
exporte JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")
# exporte JDK_HOME=$(readlink -f /usr/bin/javac | sed "s:/bin/javac::")
# exporte JAVA_ROOT=$JAVA_HOME
# exporte JAVA_BINDIR=$JAVA_HOME/bin
# exporte SDK_HOME=$JDK_HOME
export SBT_OPTS="-Xmx5G"
export ANT_OPTS="-Xmx5G"
#export COLUMNS=256
#export TERM=ansi
# problems with scala term
export TERM=xterm-color
export scalaversion=`scala -version 2>&1 | awk -F 'version' '{print $2}' | awk  '{print $1}'`
export scalaver=`echo $scalaversion | awk -F '.' '{print $1"."$2}'`
export DOCKER_BUILDKIT=1

# virsh 
alias vmls="virsh list --all"
alias vnet="virsh net-list"
alias vnetls="virsh net-dhcp-leases default"

# reset jack / headset detection
alias headset='sudo alsactl restore'

alias topsocketused="ps -ef | pgrep -lf `lsof +c 0 -i tcp -i udp | awk '{print $1}' | sort | uniq -c | sort -n | tail -1 | awk '{print $2}'`"

# modify environment variables only on specific machine
# jlu local linux
if [[ $USER = "jlu" ]] ; then
    exporte CATALINA_HOME=/usr/lib/tomcat/apache-tomcat-8.5.23
    alias mntwin="sudo mount -t ntfs-3g /dev/sda2 /mnt/win -o rw,gid=users,umask=0002,sync"
    #alias mntwin="sudo mount -t ntfs-3g /dev/sda2 /mnt/win -o ro"    
    #alias mntboot="sudo mount -t btrfs /dev/sdb5 /mnt/linux -o ro"
    #alias mntdata="sudo mount -t ext4 /dev/sdb6 /mnt/data -o ro"
    #alias casclr="rm -rf ./log/* ./commitlog/* && rm -rf ./caches/* && rm -rf ./hints/* && rm -rf ./data/*"
    alias castmp="rm -rf /tmp/cassandra/* ; mkdir -p /tmp/cassandra/log"
    alias idea="idea.sh >/dev/null 2>&1 "

    # exporte GDAL_DIR=/opt/gdal-3.4.1
    # exporte gdalnative=$GDAL_DIR/build/lib
    # exporte PDAL_DIR=/opt/PDAL-2.4.0-src/build
    # exporte PDAL_LIBRARY_PATH=$PDAL_DIR/lib
    # exporte PDAL_INCLUDE_DIRS=$PDAL_DIR/include
    
    gover=`go version 2>/dev/null | awk '{print $3}' | tr -d 'go'`
    if [[ ! -z $gover ]]; then
        exporte GOROOT=/usr/lib/go-$gover
        exporte GOROOT=/usr/lib64/go/$gover
        exporte GOROOT=/opt/go
        exporte GOPATH=$HOME/gocode
        exporte PATH=$PATH:$GOPATH/bin
        exporte PATH=$PATH:$GOROOT/bin
    fi
    exporte PATH=$PATH:/opt/cuda/bin
fi

export PIP_DEFAULT_TIMEOUT=60

# modify environment variables for everyone
exporte scriptsdir=/home/jlu/scripts
exporte PATH=$PATH:.
exporte PATH=$PATH:~/.local/bin
exporte PATH=$PATH:~/bin
exporte PATH=$PATH:~/.krew/bin
exporte PATH=$PATH:$GDAL_DIR/build/bin
exporte SPARK_HOME=/opt/spark
exporte HADOOP_HOME=/opt/hadoop
export PYTHONDONTWRITEBYTECODE=1
exporte PYTHONPATH=$PYTHONPATH:$GDAL_DIR/swig/python
exporte PYTHONPATH=$PYTHONPATH:/opt/twsapi-9.79.01/IBJts/source/pythonclient
exporte LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/local/lib64:/usr/local/lib:/opt/cuda/lib64:/opt/cuda/lib64/stubs:/opt/cuda/extras/CUPTI/lib64
#exporte LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:$GDAL_DIR/build/lib64:$GDAL_DIR/build/lib:/opt/lib64:/opt/lib
exporte PATH=$PATH:$scriptsdir
#exporte PYTHONPATH=$PYTHONPATH:.
exporte prefix=/usr
exporte exec_prefix=/usr

export GDAL_DATA=`gdal-config --datadir 2>/dev/null`
exporte CLASSPATH=$CLASSPATH:$GDAL_DIR/swig/java/gdal.jar
exporte CPLUS_INCLUDE_PATH=/usr/include/gdal
exporte C_INCLUDE_PATH=/usr/include/gdal

# Source azure env
if [ -f ~/azure.completion.sh ]; then
    source ~/azure.completion.sh
fi
if [[ -e /opt/azure-cli/az.completion ]] ; then
    source /opt/azure-cli/az.completion
fi

export iAzure=`echo $HOST | tr -s '-' ' ' | awk '{print $1}' | tr -d [a-z]`
if [[ ! -z $iAzure ]]; then export iAzureHost=`python -c "print $iAzure %10+7*($iAzure/10)" 2>/dev/null`; fi

if [[ ! -z $(which cqlsh 2>/dev/null) ]] ; then
    export CQLSH_HOST=$(myip)
fi

# git branch -d -r julien && git push origin --delete julien
# git clone --bare toto.git # takes all branches and tags
###Git uses the ^ notation to mean "one commit prior."
# git config --global user.email "julienlaurenceau@gmail.com"
# git config --global credential.helper /usr/lib/git/git-credential-gnome-keyring
# git diff HEAD^^^..HEAD -- */Compute.scala
# git diff BRANCHNAME -- ./lib
# git diff HEAD -- ./lib
# git diff stat
# git merge --squash --no-commit -Xtheirs BRANCHNAME
# git log --pretty=oneline --since="2 weeks ago"
# git log --pretty=format:'%h : %s' --date-order --graph
# git stash --keep-index
#     procedure pour merger un seul fichier dune branche
#     git checkout -b tmpbranch
#     git add the_file
#     git commit -m "stashing the_file"
#     git checkout master
# git fetch --all --tags --prune
# git checkout tags/<tag_name> -b <branch_name>
## remove a tag: git tag --delete 0.8 && git push origin :refs/tags/0.8
## move a repo : repo=toto.git && git clone --mirror dev@dev-git-01:$repo && cd $repo && git remote set-url --push origin http://GIT-01-EU.toto.local:80/$repo && git fetch -p origin && git push --mirror && cd ..

# yum install epel-release centos-extras
# yum install make gcc kernel-headers kernel-devel perl dkms bzip2 curl wget jq nmon sysstat htop vim firewalld git

# sudo add-apt-repository ppa:ubuntugis/ppa
# sudo apt install gnome-clocks chrony curl baobab ncdu gnuplot python3-pip python3-dev jq exfat-utils pidgin git git-cvs gitg lrzip figlet emacs nano nmap docker docker-compose meld libjpeg62 libreadline5 terminator tilix doxygen fakeroot clementine bzr fossil mercurial apache2-utils hexchat dstat htop nmon sysstat nethogs gdb restic rclone tcpdump iptraf iperf fio sysbench mtr xdotool xsel ghex lame fbreader ecryptfs-utils openjdk-8-jdk openjfx libopenjfx-jni libjemalloc-dev vlc libavfilter-dev libsecret-1-0 libsecret-1-dev ethtool linux-tools-common linux-tools-generic linux-cloud-tools-generic libjemalloc2 tuna hwloc pulseeffects apt-transport-https guvcview kazam gnome-tweaks gnome-shell-extensions numactl duf bat zsh exa skopeo alsa-tools tcpick
# sudo apt install cheese guvcview okular
# sudo apt install clamav clamtk clamav-daemon inotify-tools
# sudo apt install prometheus-node-exporter prometheus prometheus-alertmanager 
# sudo apt install qemu qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager libguestfs-tools ebtables
# sudo pip3 install bpytop gpustat --upgrade
# sudo ubuntu-drivers autoinstall
# sudo apt install nvidia-driver-470 
# sudo apt install linux-tools-$(uname -r) linux-cloud-tools-$(uname -r)
# sudo apt install dropwatch netdata
# sudo apt install postgresql-12
# sudo apt-mark hold postgresql-12
# sudo apt install apt-btrfs-snapshot
# sudo systemctl enable chronyd ; sudo systemctl start chronyd ; timedatectl; sudo timedatectl set-ntp true ; timedatectl

# if [[ "$USER" = "root" ]]; then
#     exportNoVoid PATH="$PATH:/opt/miniconda3/bin"
# else
#     exportNoVoid PATH="/opt/miniconda3/bin:$PATH"
#     exportNoVoid PATH="$HOME/miniconda3/bin:$PATH"
# fi

if [[ ! -z $idir ]]; then
    cd $idir
    unset idir
fi
#----------------------------------   E O F   ----------------------------------


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
unalias condaInit 2>/dev/null
# avoid to export keys (like PATH or LD_LIBRARYPATH) to value pointing to non existing path or including duplicates
condaInit()
{
    __conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/opt/miniconda3/etc/profile.d/conda.sh"
        else
            export PATH="/opt/miniconda3/bin:$PATH"
        fi
    fi
    unset __conda_setup
}
# <<< conda initialize <<<


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[[ -e ~/.cargo/env ]] && . "$HOME/.cargo/env"

[[ -e ~/.alteia.sh ]] && source ~/.alteia.sh
