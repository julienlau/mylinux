#!/bin/bash
set -ex

# edit rsyslog config for minio to log to a specific file

date

echo "# Log minio log to a separate file" > /etc/rsyslog.d/minio.conf
echo ':programname, contains, "minio" /var/log/minio.log' >> /etc/rsyslog.d/minio.conf

touch /var/log/minio.log
chown syslog:adm /var/log/minio.log
systemctl restart rsyslog
systemctl status rsyslog

# Restart of minio is not needed
date
