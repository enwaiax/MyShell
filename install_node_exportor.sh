#!/usr/bin/env bash
set -e

# check linux platform
if [ "$(uname -m)" == "x86_64" ]; then
    node_exporter_platform=amd64
elif [ "$(uname -m)" == "aarch64" ]; then
    node_exporter_platform=arm64
elif [ "$(uname -m)" == "armv7l" ]; then
    node_exporter_platform=arm
else
    echo "Unsupported platform"
    exit 1
fi

node_exporter_binary_url_prefix="https://github.com/prometheus/node_exporter/releases/download/v"
node_exporter_version="1.5.0"
node_exporter_binary="${node_exporter_binary_url_prefix}${node_exporter_version}/node_exporter-${node_exporter_version}.linux-${node_exporter_platform}.tar.gz"

if [ -f /usr/local/bin/node_exporter ]; then
    echo "node_exporter is already installed"
    rm -rf /usr/local/bin/node_exporter
fi

# download node_exporter binary and extract it
wget -q ${node_exporter_binary} -O node_exporter.tar.gz
tar -xzf node_exporter.tar.gz
cp node_exporter-${node_exporter_version}.linux-${node_exporter_platform}/node_exporter /usr/local/bin/node_exporter
rm -rf node_exporter.tar.gz node_exporter-${node_exporter_version}.linux-${node_exporter_platform}
chmod +x /usr/local/bin/node_exporter

# set prometheus runnable user
if [ "$(id -u prometheus)" ]; then
    echo "prometheus user exists"
else
    echo "create prometheus user"
    useradd -s /sbin/nologin prometheus -M
fi

# install node_exporter systemd service
cat <<EOF >/etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/node_exporter --collector.processes  --collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($|/)
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# start node_exporter service
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
systemctl status node_exporter
