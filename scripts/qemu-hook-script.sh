#!/bin/bash
#
# Hook script for QEMU (vm instanciated with KVM)
# 
# adds port forwards via IPtables to your VMs
#
# Erico Mendonca (erico.mendonca@suse.com)
# dec/2018
#
# https://github.com/doccaz/kvm-scripts
#
# Adapted by Branislav Siarsky
# apr/2020
#
# Usage: 
# copy and rename the "qemu-hook-script.sh" file to "/etc/libvirt/hooks/qemu". Please note this is a file called "qemu", not a directory.
#   sudo cp qemu-hook-script.sh /etc/libvirt/hooks/qemu
#   chmod +x /etc/libvirt/hooks/qemu
# test listener : nc -vv -l 192.168.122.20 2181
# test client   : nc -vv 192.168.60.202 2181

dbg=0
if [[ $dbg -gt 0 ]]; then
    set -x
fi
if [[ $dbg -gt 9 ]]; then
    set -e
fi

# if [[ $# -ne 2 ]] ; then
#     exit 9
# fi

log() {
    logger -t qemu-hook-script "$1"
}

addForward() {
    VM=$1
    HOST_NIC=$2
    HOST_IP=$3
    HOST_PORT=$4
    GUEST_NIC=$5
    GUEST_IP=$6
    GUEST_PORT=$7
    PROTOCOL=$8

    IPTABLES="/sbin/iptables"
    IP="/sbin/ip"
    HOST_IP_MASK="24"
    IPTABLES_ACTION=""
    IPTABLES_TEXT=""
    IP_ACTION=""
    IP_TEXT=""

    if [[ $# -eq 8 && -e ${IP} && -e ${IPTABLES} ]]; then
        if [ "${VM}" == "${VM_NAME}" ]; then
            if [ "${ACTION}" == "stopped" ]; then
                IPTABLES_ACTION="-D"
                IPTABLES_TEXT="Removing forwarding rules for VM ${VM}"
                IP_ACTION="del"
                IP_TEXT="Removing IP ${HOST_IP} from ${HOST_NIC}"
            fi

            if [ "${ACTION}" == "start" ] || [ "${ACTION}" == "reconnect" ]; then
                IPTABLES_ACTION="-I"
                IPTABLES_TEXT="Adding forwarding rules for VM ${VM}: host port ${HOST_PORT} will be redirected to ${GUEST_IP}:${GUEST_PORT} on interface ${GUEST_NIC}"
                IP_ACTION="add"
                IP_TEXT="Adding IP ${HOST_IP} to ${HOST_NIC}"
            fi

            if [ "${IPTABLES_ACTION}" == "" ]; then
                log "Action ${ACTION} on domain $VM not configured, ignoring"
                exit 0
            else 
                log "Action ${ACTION} on domain $VM called"
            fi

            log "${IPTABLES_TEXT}"
            ${IPTABLES} ${IPTABLES_ACTION} FORWARD -o ${GUEST_NIC} -d ${GUEST_IP} -j ACCEPT

            # if [[ "${PROTOCOL}" = "all" ]] ; then # --dport does not work with protocol=all
            #     ${IPTABLES} -t nat ${IPTABLES_ACTION} PREROUTING -d ${HOST_IP} -p all --dport ${HOST_PORT} -j DNAT --to ${GUEST_IP}:${GUEST_PORT}
            if [[ "${PROTOCOL}" == "all" ]] || [[ "${PROTOCOL}" == *"tcp"* ]] || [[ "${PROTOCOL}" == *"TCP"* ]]; then
                ${IPTABLES} -t nat ${IPTABLES_ACTION} PREROUTING -d ${HOST_IP} -p tcp --dport ${HOST_PORT} -j DNAT --to ${GUEST_IP}:${GUEST_PORT}
            fi
            
            if [[ "${PROTOCOL}" == "all" ]] || [[ "${PROTOCOL}" == *"udp"* ]] || [[ "${PROTOCOL}" == *"UDP"* ]]; then
                ${IPTABLES} -t nat ${IPTABLES_ACTION} PREROUTING -d ${HOST_IP} -p udp --dport ${HOST_PORT} -j DNAT --to ${GUEST_IP}:${GUEST_PORT}
            fi

            # if [[ "${PROTOCOL}" == *"icmp"* ]] || [[ "${PROTOCOL}" == *"ICMP"* ]]; then
            #     ${IPTABLES} -t nat ${IPTABLES_ACTION} PREROUTING -d ${HOST_IP} -p icmp --dport ${HOST_PORT} -j DNAT --to ${GUEST_IP}:${GUEST_PORT}
            # fi
            
            # Warning this could delete HOST_NIC if bypassing the IF !!!
            # if [[ "${IP_ACTION}" = "add" ]] ; then
            #     log "${IP_TEXT}"
            #     $IP address ${IP_ACTION} ${HOST_IP}/${HOST_IP_MASK} dev ${HOST_NIC} 
            # fi
        fi
    fi
}
## main program
VM_NAME=${1}
ACTION=${2}
##
if [[ $dbg -gt 0 ]]; then
    echo "STATUS BEFORE"
    # iptables -L FORWARD -nv --line-number
    #iptables -L -vt nat
    iptables-save
    # iptables -S
fi

log "qemu hook script execution ${VM_NAME} ${ACTION}"

### declare your port forwards here
### format: addForward <VM> <source nic> <source address> <source port> <destination nic> <destination address> <destination port> <protocol>
#Port 80 forward:   addForward debian10-vm2 enp3s0f0 192.168.1.17 80 virbr0 192.168.122.2 80 tcp
#All ports forward: addForward debian10-vm2 enp3s0f0 192.168.1.17 1:65535 virbr0 192.168.122.2 1-65535 tcp,udp
#addForward debian10-vm1 enp3s0f0 192.168.1.16 1:65535 virbr0 192.168.122.16 1-65535 tcp
#addForward debian10-vm2 enp3s0f0 192.168.1.17 1:65535 virbr0 192.168.122.17 1-65535 tcp
#addForward debian10-vm3 enp3s0f0 192.168.1.18 1:65535 virbr0 192.168.122.18 1-65535 tcp

addForward ubuntu-20 eno2 192.168.60.202 2181  virbr0 192.168.122.20 2181 tcp,udp
addForward ubuntu-20 eno2 192.168.60.202 2888  virbr0 192.168.122.20 2888 tcp,udp
addForward ubuntu-20 eno2 192.168.60.202 3888  virbr0 192.168.122.20 3888 tcp,udp
addForward ubuntu-20 eno2 192.168.60.202 2220  virbr0 192.168.122.20 22   tcp,udp
addForward ubuntu-20 eno2 192.168.60.202 39120 virbr0 192.168.122.20 9100 tcp,udp

# addForward ubuntu-21 eno2 192.168.60.202 3181  virbr0 192.168.122.21 3181 tcp,udp
# addForward ubuntu-21 eno2 192.168.60.202 8000  virbr0 192.168.122.21 8000 tcp,udp
# addForward ubuntu-21 eno2 192.168.60.202 6650  virbr0 192.168.122.21 6650 tcp,udp
# addForward ubuntu-21 eno2 192.168.60.202 8080  virbr0 192.168.122.21 8080 tcp,udp
addForward ubuntu-21 eno2 192.168.60.202 2221  virbr0 192.168.122.21 22   tcp,udp
addForward ubuntu-21 eno2 192.168.60.202 39150 virbr0 192.168.122.21 9100 tcp,udp

addForward ubuntu-22 eno2 192.168.60.202 4369  virbr0 192.168.122.22 4369 tcp,udp
addForward ubuntu-22 eno2 192.168.60.202 5672  virbr0 192.168.122.22 5672 tcp,udp
addForward ubuntu-22 eno2 192.168.60.202 2222  virbr0 192.168.122.22 22   tcp,udp
addForward ubuntu-22 eno2 192.168.60.202 39150 virbr0 192.168.122.22 9100 tcp,udp

addForward ubuntu-30 eno2 192.168.60.203 2181  virbr0 192.168.122.30 2181 tcp,udp
addForward ubuntu-30 eno2 192.168.60.203 2888  virbr0 192.168.122.30 2888 tcp,udp
addForward ubuntu-30 eno2 192.168.60.203 3888  virbr0 192.168.122.30 3888 tcp,udp
addForward ubuntu-30 eno2 192.168.60.203 2230  virbr0 192.168.122.30 22   tcp,udp
addForward ubuntu-30 eno2 192.168.60.203 39130 virbr0 192.168.122.30 9100 tcp,udp

# addForward ubuntu-31 eno2 192.168.60.203 3181  virbr0 192.168.122.31 3181 tcp,udp
# addForward ubuntu-31 eno2 192.168.60.203 8000  virbr0 192.168.122.31 8000 tcp,udp
# addForward ubuntu-31 eno2 192.168.60.203 6650  virbr0 192.168.122.31 6650 tcp,udp
# addForward ubuntu-31 eno2 192.168.60.203 8080  virbr0 192.168.122.31 8080 tcp,udp
addForward ubuntu-31 eno2 192.168.60.203 2231  virbr0 192.168.122.31 22   tcp,udp
addForward ubuntu-31 eno2 192.168.60.203 39150 virbr0 192.168.122.31 9100 tcp,udp

addForward ubuntu-40 eno2 192.168.60.204 2181  virbr0 192.168.122.40 2181 tcp,udp
addForward ubuntu-40 eno2 192.168.60.204 2888  virbr0 192.168.122.40 2888 tcp,udp
addForward ubuntu-40 eno2 192.168.60.204 3888  virbr0 192.168.122.40 3888 tcp,udp
addForward ubuntu-40 eno2 192.168.60.204 2240  virbr0 192.168.122.40 22   tcp,udp
addForward ubuntu-40 eno2 192.168.60.204 39140 virbr0 192.168.122.40 9100 tcp,udp

addForward ubuntu-41 eno2 192.168.60.204 2241  virbr0 192.168.122.41 22   tcp,udp
addForward ubuntu-41 eno2 192.168.60.204 39141 virbr0 192.168.122.41 9100 tcp,udp

# addForward ubuntu-50 eno2 192.168.60.205 3181  virbr0 192.168.122.50 3181 tcp,udp
# addForward ubuntu-50 eno2 192.168.60.205 8000  virbr0 192.168.122.50 8000 tcp,udp
# addForward ubuntu-50 eno2 192.168.60.205 6650  virbr0 192.168.122.50 6650 tcp,udp
# addForward ubuntu-50 eno2 192.168.60.205 8080  virbr0 192.168.122.50 8080 tcp,udp
addForward ubuntu-50 eno2 192.168.60.205 2250  virbr0 192.168.122.50 22   tcp,udp
addForward ubuntu-50 eno2 192.168.60.205 39150 virbr0 192.168.122.50 9100 tcp,udp


if [[ $dbg -gt 0 ]]; then
    echo "STATUS AFTER"
    iptables-save
fi

