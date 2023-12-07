#!/usr/bin/env bash
set -e

prom_version=2.48.0
install_dir=/opt
data_dir=/data/prometheus/data

mkdir -p ${data_dir} /etc/prometheus

cd /tmp

curl -LO "https://github.com/prometheus/prometheus/releases/download/v${prom_version}/prometheus-${prom_version}.linux-amd64.tar.gz"
tar -xvzf prometheus-${prom_version}.linux-amd64.tar.gz
rm -f prometheus-${prom_version}.linux-amd64.tar.gz
mv prometheus-${prom_version}.linux-amd64 ${install_dir}/prometheus-${prom_version}.linux-amd64
rm -f ${install_dir}/prometheus
ln -s ${install_dir}/prometheus-${prom_version}.linux-amd64 ${install_dir}/prometheus
ls -la ${install_dir}/prometheus/prometheus

cat <<EOF > /etc/default/prometheus
# Set the command-line arguments to pass to the server.
# Due to shell escaping, to pass backslashes for regexes, you need to double
# them (\\d for \d). If running under systemd, you need to double them again
# (\\\\d to mean \d), and escape newlines too.
ARGS="--web.enable-admin-api --storage.tsdb.path=/data/prometheus/data --storage.tsdb.retention.time=45d"
EOF

cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval:     30s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 30s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'test'

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['localhost:9093']

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  - job_name: 'prometheus'
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
      - targets: ['localhost:9090']
  - job_name: node
    # Override the global default and scrape targets from this job
    scrape_interval: 10s
    scrape_timeout: 10s
    static_configs:
      - targets: ['localhost:9100', 'vm1:9100', 'vm2:9100', 'vm3:9100']
  - job_name: cassandra_exporter
    static_configs:
      - targets: ['localhost:9105', 'vm1:9105', 'vm2:9105', 'vm3:9105']

EOF

cat <<EOF > /lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus exporter for machine metrics
Documentation=https://github.com/prometheus/node_exporter

[Service]
Restart=on-failure
User=prometheus
Group=prometheus
Type=simple
EnvironmentFile=/etc/default/prometheus
ExecStart=${install_dir}/prometheus/prometheus --config.file=/etc/prometheus/prometheus.yml \$ARGS
ExecReload=/bin/kill -HUP \$MAINPID
TimeoutStopSec=20s
SendSIGKILL=no

# systemd hardening-options
AmbientCapabilities=
CapabilityBoundingSet=
DeviceAllow=/dev/null rw
DevicePolicy=strict
LimitMEMLOCK=0
LimitNOFILE=32768
LockPersonality=true
MemoryDenyWriteExecute=true
NoNewPrivileges=true
PrivateDevices=true
PrivateTmp=true
PrivateUsers=true
ProtectControlGroups=true
#ProtectHome=true
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectSystem=full
RemoveIPC=true
RestrictNamespaces=true
RestrictRealtime=true
SystemCallArchitectures=native

[Install]
WantedBy=multi-user.target
EOF
cat /lib/systemd/system/prometheus.service

sudo useradd --no-create-home --shell /bin/false prometheus || echo "User already exists."

chmod go+r /etc/default/prometheus
chown -R prometheus:prometheus ${install_dir}/prometheus-${prom_version}.linux-amd64 ${data_dir} /etc/prometheus/prometheus.yml

systemctl daemon-reload
systemctl enable prometheus.service
systemctl start prometheus.service
echo "systemctl status prometheus"
systemctl status prometheus

ss -ntpl | grep 9090