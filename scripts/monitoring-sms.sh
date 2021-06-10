#!/bin/bash 
#
# StackX Monitoring System (SMS)
# sms.sh / lamp_monitoring.stackx.sh
# Author: Christophe Casalegno / Brain 0verride
# Contact: brain@christophe-casalegno.com
# Version 1.0.0
#
# Copyright (c) 2020 Christophe Casalegno
# 
# This program is free software: you can redistribute it and/or modify
#
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>
#
# The license is available on this server here: 
# https://www.christophe-casalegno.com/licences/gpl-3.0.txt
#
# To inlude in a php page for example: (dont forget to put your script in a 
# directory not readable by your web server)
#
# The graphic banner is available here: 
# https://www.christophe-casalegno.com/banners/ScalarX.jpg
# 
# <?php
#
# function checkall()
# {
#	$homecheck = "/home/sx/data";
#	$checkscript = "lamp_monitoring.stackx.sh";
#	$check="$homecheck/$checkscript";
#	system("$check");
# }
#
# checkall();
# ?>
#
# Example for a CONF_FILE: (with only needed variable for this script)
# loginsxmysql:sx
# passsxmysql:prxotpoofas
#
# Example for process2monitor.txt (generated automatically by my deployer for each server)
# apache2 
# fail2ban-server 
# memcached 
# miniserv.pl 
# php-fpm5.6 
# php-fpm7.0 
# php-fpm7.1 
# php-fpm7.2 
# php-fpm7.3 
# php-fpm7.4 
# php-fpm8.0 
# pure-ftpd 
# sshd 
#
# Example for fs_list.txt (generated automatically by my deployer for each server)
# 
# grep -v '#' /etc/fstab |awk '{print $2}' > fs_list.txt 
# 
# If you use other filesystem like network sshfs you may add:
# grep  'sshfs' /etc/fstab |awk '{print $2}' >> fs_list.txt
# 
# Result can be something like : 
# /
# /datastore
# /datadrop/cd101
# etc. depending of your configuration
#
# Need to check more tcp services on a limited system without netcat, etc.? 
# You can use directly: 
# timeout 1 cat </dev/tcp/$ip/port to create your own tcp banner grabber. 
# For example : timeout 1 cat </dev/tcp/127.0.0.1/65022



CONF_FILE="/home/sx/.sx" # Replace by your config file

function read_config()
{
	CONF_FILE="$1"
	VAR_CONF=$(cat $CONF_FILE |sed "s/ /_/g")

	for LINE in $VAR_CONF
	do
		VARNAME=$(echo $LINE |cut -d ":" -f1 |tr [:lower:] [:upper:])
		VAR=$(echo $LINE |grep -w "$VAR_CONF" |cut -d ":" -f2)
		eval ${VARNAME}=$VAR
	done
}

read_config $CONF_FILE

function checktest()
{
  if [ "$1" -eq 0 ] 

       then
                       echo "<font size=-1>$2:</font> <font size=-1 color="#64FE2E">OK</font>"    
                       
       else
                       echo "<font size=-1>$2:</font> <font size=-1 color="red">ERROR</font>"    
                       
fi
echo '<br>'
}

function checkwarning()
{
	if [ "$1" -eq 0 ]
	then
		echo "<font size=-1>$2:</font> <font size=-1 color="#64FE2E">OK</font>"
	else
		echo "<font size=-1>$2:</font> <font size=-1 color="yellow">WARNING</font>"
	fi
echo '<br>'
}	

function startpage()
{
	HTML_TITLE="$1"
	echo '<html>'
	echo '<head>'
	echo "<title>$HTML_TITLE</title>"
	echo '</head>'
	echo  '<body bgcolor="#000000" text="white">'
}


function title()
{
	TITLE="$1"
	echo '<table><tr><td valign="middle">'
	echo '<img src="ScalarX.jpg" alt="ScalarX">'
	echo '</td><td width="5"></td><td valign="middle">'
	echo "<font size +5><strong>$TITLE</strong></font>"
	echo '</td></tr></table>'
	echo '<hr width="600" align="left">'
}

function titlecheck()
{
	TITLE_CHECK="$1"
  	echo "<br>"
  	echo "<font size=-1><strong>$TITLE_CHECK check</strong></font>"
  	echo "<hr>"
}

function table_init()
{
	echo '<table width=600><tr><td valign="top">'
}

function center_column()
{
echo '</td>'
echo '<td width="20"></td>'
echo '<td valign="top">'
}

function table_end()
{
	echo '</td></tr></table>'
}

function endpage()

{
	echo "</body>";
	echo "</html>";
}

PROCESS_CONF="/home/sx/data/process2monitor.txt"
FILE2CHECK=$(cat $PROCESS_CONF)

function check_process()

{
	P2CHECK="$1"
	PROCESS=$(pgrep -c "$P2CHECK")
	
	if [[ "$PROCESS" -eq 0 ]]
	then
		echo "<font size=-1>$P2CHECK:</font> <font size=-1 color="red">ERROR</font>"
	else
		echo "<font size=-1>$P2CHECK ($PROCESS):</font> <font size=-1 color="#64FE2E">OK</font>"
	fi

}

function internet_check()
{
	
	titlecheck "Internet"
	for DNS in "$@"
	do
		CHECK_DNS_PING=$(ping -c 1 -W 1 $DNS > /dev/null; echo "$?")
		checkwarning "$CHECK_DNS_PING" "$DNS ping"	
	done

}

function dns_check()
{
	titlecheck "DNS resolve"
	for DNS in "$@"
	do
		CHECK_DNS_RESOLVE=$(dig +time=0 +tries=1 $DNS > /dev/null; echo "$?")
		checkwarning "$CHECK_DNS_RESOLVE" "$DNS host"
	done
}

function mysql_check()
{
	LOGINSXSQL="$1"
	DBPASSWORDSQL="$2"
	REPLICATION_TRESHOLD="$3"
	DBSXSQL="sx"
	TABLE_NAME="sx_test"
	ERRORS=()
	
	CONNECT="mysql -u$LOGINSXSQL --database=$DBSXSQL -p$DBPASSWORDSQL -e "

	titlecheck "MySQL / MariaDB"

	CONNECTION_SQL=$($CONNECT "SHOW VARIABLES LIKE '%version%';" > /dev/null; echo "$?")
  checktest "$CONNECTION_SQL" "Connexion SQL"	

	CREATE_TABLE=$($CONNECT "CREATE TABLE $TABLE_NAME(test varchar(255));" >/dev/null; echo "$?")
	checktest "$CREATE_TABLE" "Create table"

	SHOW_TABLE=$($CONNECT "SHOW TABLES;" > /dev/null; echo "$?")
	checktest "$SHOW_TABLE" "Show tables"

	DELETE_TABLE=$($CONNECT "DROP TABLE $TABLE_NAME;" >/dev/null; echo "$?")
	checktest "$DELETE_TABLE" "Delete table"

	if [[ $REPLICATION_TRESHOLD != '0' ]]
	then

	titlecheck "Replication MySQL / MariaDB"
	
	SLAVE_STATUS=$($CONNECT "SHOW SLAVE STATUS\G" |grep -v row)
	
	LAST_ERRNO=$(echo "$SLAVE_STATUS" |grep "Last_Errno:" |awk '{print $2}')
	if [[ $LAST_ERRNO = 0 ]]
	then
		echo '<font size=-1>Last_Errno:</font> <font size=-1 color="#64FE2E"><strong>OK</strong></font>'
	else
		echo '<font size=-1>Last_Errno:</font> <font size=-1 color="red"><strong>ERROR</strong></font>'
	fi
	echo '<BR>'	
	
	REPLICATION_LATE=$(echo "$SLAVE_STATUS" |grep  "Seconds_Behind_Master:" | awk '{ print $2 }' )
	
	if [[ $REPLICATION_LATE == "NULL" ]]
	then
		echo '<font size=-1>Second(s)_late:</font> <font size=-1 color="red"><strong>ERROR</strong></font>'
	
	elif [[ $REPLICATION_LATE -gt $REPLICATION_TRESHOLD ]] 
	then
		echo "<font size=-1>Second(s)_late:</font> <font size=-1 color="red"><strong>ERROR ($REPLICATION_LATE)</strong></font>"
	else
		echo "<font size=-1>Second(s)_late:</font> <font size=-1 color="#64FE2E"><strong>OK ($REPLICATION_LATE)</strong></font>"
	fi

	echo '<BR>'

	SLAVE_IO_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_IO_Running:" | awk '{ print $2 }' )
	
	if [[ $SLAVE_IO_RUNNING = "Yes" ]] 
	
	then 
		echo '<font size=-1>S_IO_Running:</font> <font size=-1 color="64FE2E"><strong>OK</strong></font>'
	else
		echo '<font size=-1>S_IO_Running:</font> <font size=-1 color="red"><strong>ERROR</strong></font>'
	fi

	echo '<BR>'

	SLAVE_SQL_RUNNING=$(echo "$SLAVE_STATUS" | grep "Slave_SQL_Running:" | awk '{ print $2 }')
	
	if [[ $SLAVE_SQL_RUNNING = "Yes" ]]
	then
		echo '<font size=-1>S_SQL_Running</font> <font size=-1 color="64FE2E"><strong>OK</strong></font>'
	else
		echo '<font size=-1>S_SQL_Running</font> <font size=-1 color="red"><strong>ERROR</strong></font>'
	fi

	echo '<BR>'

else
	true
fi

}

function memcached_check()
{
	IP="$1"
	PORT="$2"

	titlecheck "Memcached"
	
	MEMCACHED=$(echo stats |timeout 1 bash -c "</dev/tcp/$IP/$PORT" > /dev/null; echo "$?")

	checktest "$MEMCACHED" "Memcached connect (port 11211)"
}

function disk_check()

{
	
	SPACE_ERROR_TRESHOLD="$1"
	SPACE_WARNING_TRESHOLD="$2"
	INODES_ERROR_TRESHOLD="$3"
	INODES_WARNING_TRESHOLD="$4"

	titlecheck "Disks"

	LIST_DISK=$(df -x tmpfs -x devtmpfs | grep 'dev' |awk -F " " '{print $1}' |cut -d/ -f3)
	
	for DISK in $LIST_DISK
	do
		SPACE_USED_PERCENT=$(df |grep -w "$DISK" |head -1|awk -F" " '{print $5}' |cut -d% -f1)
		SPACE_USED=$(df -x tmpfs -x devtmpfs -h |grep "$DISK" |head -1 |awk -F " " '{print $3}')
		SPACE_TOTAL=$(df -x tmpfs -x devtmpfs -h |grep "$DISK" |head -1 |awk -F " " '{print $2}')

		if [[ "$SPACE_USED_PERCENT" -gt "$SPACE_ERROR_TRESHOLD" ]]
		then
			echo "<font size=-1>Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:</font> <font size=-1 color=red>ERROR</font><br>"
		elif [[ "$SPACE_USED_PERCENT" -gt "$SPACE_WARNING_TRESHOLD" ]]
		then
			echo "<font size=-1>Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:</font> <font size=-1 color=yellow>WARNING</font><br>"
		else
			echo "<font size=-1>Part: <strong>$DISK</strong> - $SPACE_USED / $SPACE_TOTAL ($SPACE_USED_PERCENT%) space:</font> <font size=-1 color=#64FE2E>OK</font><br>"
		fi

		INODES_USED_PERCENT=$(df -i|grep -w "$DISK" |head -1 |awk -F" " '{print $5}' |cut -d% -f1)
		INODES_USED=$(df -i -h |grep -w "$DISK" |head -1 |awk -F" " '{print $3}' |cut -d% -f1)
		INODES_TOTAL=$(df -i -h |grep -w "$DISK" |head -1 |awk -F" " '{print $2}')

		if [[ "$INODES_USED_PERCENT" -gt "$INODES_ERROR_TRESHOLD" ]]
		then
			echo "<font size=-1>Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:</font> <font size=-1 color=red>ERROR</font><br>"
		elif [[ "$INODES_USED_PERCENT" -gt "$INODES_WARNING_TRESHOLD" ]]
		then
			echo "<font size=-1>Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:</font> <font size=-1 color=yellow>WARNING</font><br>"
		else
			echo "<font size=-1>Part: <strong>$DISK</strong> - $INODES_USED / $INODES_TOTAL ($INODES_USED_PERCENT%) inodes:</font> <font size=-1 color=#64FE2E>OK</font><br>"
		fi

	done
}

function mem_check()

{
	MEM_ERROR_TRESHOLD="$1"
	MEM_WARNING_TRESHOLD="$2"	
	MEM_TOTAL=$(free -h |grep Mem |awk '{print $2}' |cut -d "i" -f1)

	titlecheck "Memory"

	MEM_USED_PERCENT=$(free |awk 'FNR == 2 {print 100-(($2-$3)/$2)*100}' |cut -d "." -f1)
	MEM_USED=$(free -h |grep Mem |awk '{print $3}' |cut -d "i" -f1)

	if [[ "$MEM_USED_PERCENT" -gt "$MEM_ERROR_TRESHOLD" ]]
	then
		echo "<font size=-1>Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):</font> <font size=-1 color="red">ERROR</font>"
	elif [[ "$MEM_USED_PERCENT" -gt "$MEM_WARNING_TRESHOLD" ]]
	then
		echo "<font size=-1>Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):</font> <font size=-1 color="yellow">WARNING</font>"
	else
		echo "<font size=-1>Memory usage: $MEM_USED / $MEM_TOTAL ($MEM_USED_PERCENT%):</font> <font size=-1 color="#64FE2E">OK</font>"
	fi
}

function load_check()
{
	THREADS=$(grep processor /proc/cpuinfo |wc -l)
	LOAD_TRESHOLD=$(echo $(($THREADS * 2)))
	WAIT_B4_CHECK="1"

	echo "<br>"
	titlecheck "Load Average"

	LOAD_AVERAGE1=$(awk '{print $1}' < /proc/loadavg |cut -d "." -f1)
	sleep "$WAIT_B4_CHECK"
	LOAD_AVERAGE2=$(awk '{print $1}' < /proc/loadavg |cut -d "." -f1)
	
	if [[ "$LOAD_AVERAGE1" -ge "$LOAD_TRESHOLD" ]]
	then
		if [[ "$LOAD_AVERAGE2" -ge "$LOAD_AVERAGE1" ]]
		then
			echo "<font size=-1>Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s):</font> <font size=-1 color="red">ERROR</font>"
		else
			echo "<font size=-1>Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s) but going down:</font> <font size=-1 color="yellow">WARNING</font>"		
		fi
	else
		echo "<font size=-1>Load average ($LOAD_AVERAGE2 / $LOAD_TRESHOLD) / $THREADS core(s):</font> <font size=-1 color="#64FE2E">OK</font>"

	fi
}

function all_process_check()
{
for LINE2CHECK in $FILE2CHECK
do

	check_process "$LINE2CHECK"
	echo "<BR>"

done
}

function fs_check()
{
	
	FS_ACTIVE="$1"

	if [[ $FS_ACTIVE = "yes" ]]
	then
			titlecheck "Filesystems"
	
		for LINE in $(cat /home/sx/data/fs_list.txt)
		do
				FS=$(df -x tmpfs -x devtmpfs |grep '\|@' |grep $LINE)

				if [[ -z "$FS" ]]
				then
							echo "<font size=-1>$LINE:</font> <font size=-1 color="red">ERROR</font>"
				else
							echo "<font size=-1>$LINE:</font> <font size=-1 color="#64FE2E">OK</font>"
				fi 
		done
	else
			true
	fi

}

startpage "StackX Local monitoring"

title "StackX Monitoring System"

table_init

titlecheck "Server process"

all_process_check

internet_check 1.1.1.1 8.8.8.8

dns_check google.com cloudflare.com

fs_check

center_column

mysql_check $LOGINSXMYSQL $PASSSXMYSQL 0

memcached_check 127.0.0.1 11211

disk_check 95 90 95 90

mem_check 95 90

load_check

table_end

endpage
