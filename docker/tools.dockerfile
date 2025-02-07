# docker build --progress=plain -t pepitedata/tools:focal -f tools.dockerfile .
FROM ubuntu:focal

RUN groupadd -g 10001 me && useradd me -m -u 10000 -g 10001 -s /bin/bash

RUN set -ex && \
    apt-get update && \
    ln -s /lib /lib64 && \
    apt install -y atop bash binutils curl dnsutils dstat fio gawk htop iftop inetutils-traceroute ioping iotop iperf iptraf iputils-tracepath iputils-ping libc6 lsof netcat nethogs net-tools nmap nmon openssl procps qperf rclone strace sudo sysbench sysstat tini vim python3 python3-requests python3-yaml python3-kubernetes python3-lxml jq && \
    rm /bin/sh && \
    ln -sv /bin/bash /bin/sh && \
    chgrp root /etc/passwd && chmod ug+rw /etc/passwd && \
    rm -rf /var/cache/apt/*

RUN ln -s /usr/bin/python3 /usr/bin/python && \
    ls -la /usr/bin/python* && \
    readlink -f /usr/bin/python*

RUN usermod -aG sudo me && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

WORKDIR /home/me
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

# Specify the User that the actual main process will run as
USER me
