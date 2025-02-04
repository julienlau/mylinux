# docker build --progress=plain -t pepitedata/kube-delete-old-pods:edge -f kube-delete-old-pods.dockerfile .
FROM ubuntu:focal

USER    root

ENV     username=script
ENV     zuid=10000
RUN     groupadd -g ${zuid} ${username} &&\
        useradd -l ${username} -u ${zuid} -g ${zuid} -m -s /bin/bash &&\
        mkdir -p /app &&\
        mkdir -p /usr/local/share/ca-certificates &&\
        chown ${username} /app
#######################
RUN     dpkg --configure -a && \
    apt-get install -fy --no-install-recommends && \
    apt-get autoclean && \
    apt-get autoremove --purge -y && \
    apt-get update --fix-missing -y && \
    apt-get install -y --allow-downgrades --fix-missing --no-install-recommends -o Dpkg::Options::='--force-confnew' bash openssl python3 python3-requests python3-yaml python3-kubernetes python3-lxml unattended-upgrades unzip xz-utils &&\
    unattended-upgrade -d && \
    apt-get clean

USER    ${username}
WORKDIR /app
SHELL   ["/bin/bash", "-c"]
COPY    ./kube-delete-old-pods.py /app/kube-delete-old-pods.py
ENTRYPOINT ["python3", "/app/kube-delete-old-pods.py"]