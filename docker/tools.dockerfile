# docker build --progress=plain -t pepitedata/tools:focal -f tools.dockerfile .
FROM ubuntu:focal

ARG me_uid=185
RUN groupadd -g 186 me && useradd me -m -u 185 -g 186 -s /bin/bash

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y atop bash binutils curl dnsutils dstat fio gawk htop iftop inetutils-traceroute ioping iotop iperf iptraf iputils-tracepath iputils-ping libc6 lsof netcat nethogs net-tools nmap nmon openssl procps python3 qperf rclone strace sudo sysbench sysstat tini vim && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

RUN usermod -aG sudo me && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Specify the User that the actual main process will run as
USER ${me_uid}
