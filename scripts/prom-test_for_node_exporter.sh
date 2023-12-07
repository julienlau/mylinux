#!/bin/bash

# to send a fake error message in systemd log you can use:
# echo '<4>test julien' | systemd-cat -t test

# to be adapted
interval=60s

if [[ "${HOSTNAME}" = "test" ]] ; then
    listservice="fail2ban firewalld kong postgresql-10"
    environment=int
    region=gra
    role=load-balancer
else
    # default value
    listservice="dbus fail2ban firewalld"
    environment=int
    region=legacy
    role=backend
fi

### to have info service by service
# for myservice in $listservice ; do
#     mystate=`systemctl is-active ${myservice} >/dev/null 2>&1 && echo 1 || echo 0`
#     echo "systemctl-active,host=${HOSTNAME},type=${myservice} status=${mystate}"
# done
# for myservice in $listservice ; do  mystate=`systemctl is-active ${myservice} >/dev/null 2>&1 && echo 1 || echo 0`; echo "systemctl-active,host=${HOSTNAME},type=${myservice} status=${mystate}"; done

[[ `systemctl is-active ${listservice} 2>/dev/null | grep -c "^active"` -eq `echo ${listservice} | wc -w` ]] && echo "systemctl_ok 1" || echo "systemctl_ok 0"

# ignore error on sshd
errorInLogs=`journalctl -p 1..4 --since=-${interval} 2>/dev/null | grep -v -e ' sshd' -e "^--" -e ": imjournal: journal reloaded..." | wc -l`
[[ ${errorInLogs} == 0 ]] && echo "journalctl_ok 1" || echo "journalctl_ok 0"

# hack to check that a process is running:
serviceprocess=1
if [[ "${HOSTNAME}" = "prd" ]] ; then
    if [[ `ps -ef | grep "node" | grep -c "app.js$"` -ne 1 ]] ; then
        serviceprocess=0
    fi
fi
echo "serviceprocess_ok ${serviceprocess}"

echo 'machine_role{role="'${role}'"} 1'
echo 'machine_env{env="'${environment}'"} 1'
echo 'machine_region{region="'${region}'"} 1'
