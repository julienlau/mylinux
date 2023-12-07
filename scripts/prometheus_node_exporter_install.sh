#!/usr/bin/env bash
set -e

node_version=1.7.0
install_dir=/opt

cd /tmp

curl -LO "https://github.com/prometheus/node_exporter/releases/download/v${node_version}/node_exporter-${node_version}.linux-amd64.tar.gz"
tar -xvzf node_exporter-${node_version}.linux-amd64.tar.gz
rm -f node_exporter-${node_version}.linux-amd64.tar.gz
mv node_exporter-${node_version}.linux-amd64 ${install_dir}/node_exporter-${node_version}.linux-amd64
rm -f ${install_dir}/node_exporter
ln -s ${install_dir}/node_exporter-${node_version}.linux-amd64 ${install_dir}/node_exporter
ls -la ${install_dir}/node_exporter/node_exporter

cat <<EOF > /etc/default/prometheus-node-exporter
# Set the command-line arguments to pass to the server.
# Due to shell escaping, to pass backslashes for regexes, you need to double
# them (\\d for \d). If running under systemd, you need to double them again
# (\\\\d to mean \d), and escape newlines too.
ARGS=""
EOF

cat <<EOF > /lib/systemd/system/prometheus-node-exporter.service
[Unit]
Description=Prometheus exporter for machine metrics
Documentation=https://github.com/prometheus/node_exporter

[Service]
Restart=on-failure
User=node_exporter
Group=node_exporter
Type=simple
EnvironmentFile=/etc/default/prometheus-node-exporter
ExecStart=${install_dir}/node_exporter/node_exporter \$ARGS
ExecReload=/bin/kill -HUP \$MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

[Install]
WantedBy=multi-user.target
EOF
cat /lib/systemd/system/prometheus-node-exporter.service

sudo useradd --no-create-home --shell /bin/false node_exporter || echo "User already exists."

chmod go+r /etc/default/prometheus-node-exporter
chown -R node_exporter:node_exporter ${install_dir}/node_exporter-${node_version}.linux-amd64

systemctl daemon-reload
systemctl enable prometheus-node-exporter.service
systemctl start prometheus-node-exporter.service
echo "systemctl status prometheus-node-exporter"
systemctl status prometheus-node-exporter

ss -ntpl | grep 9100