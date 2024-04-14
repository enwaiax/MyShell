#!/usr/bin/env bash
set -e

# Check if the script is running as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root"
    exit 1
fi

# Detect platform architecture
case "$(uname -m)" in
x86_64)
    node_exporter_platform=amd64
    ;;
aarch64)
    node_exporter_platform=arm64
    ;;
armv7l)
    node_exporter_platform=arm
    ;;
*)
    echo "Unsupported platform"
    exit 1
    ;;
esac

# Set variables
node_exporter_dir="/usr/local/bin"
node_exporter_binary="${node_exporter_dir}/node_exporter"
node_exporter_binary_url_prefix="https://github.com/prometheus/node_exporter/releases/download/v"
node_exporter_version="1.7.0"
node_exporter_download_url="${node_exporter_binary_url_prefix}${node_exporter_version}/node_exporter-${node_exporter_version}.linux-${node_exporter_platform}.tar.gz"
tmp_dir=$(mktemp -d)

# Check if Node Exporter is already installed
if [ -f "${node_exporter_binary}" ]; then
    echo "Node Exporter is already installed. Do you want to reinstall? (y/n)"
    read -r reinstall
    if [ "$reinstall" != "y" ]; then
        exit 0
    fi
fi

# Download and extract Node Exporter
echo "Downloading Node Exporter ${node_exporter_version} for ${node_exporter_platform}..."
wget -q "${node_exporter_download_url}" -O "${tmp_dir}/node_exporter.tar.gz" || exit 1
tar -xzf "${tmp_dir}/node_exporter.tar.gz" -C "${tmp_dir}" || exit 1

# Install Node Exporter
install -m 755 "${tmp_dir}/node_exporter-${node_exporter_version}.linux-${node_exporter_platform}/node_exporter" "${node_exporter_binary}" || exit 1

# Create Prometheus user if it doesn't exist
if ! id -u prometheus >/dev/null 2>&1; then
    echo "Creating 'prometheus' user..."
    useradd -r -s /sbin/nologin prometheus
fi

# Install node_exporter systemd service
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

# Reload systemd, enable and start Node Exporter service
systemctl daemon-reload
systemctl enable node_exporter
systemctl restart node_exporter
systemctl status node_exporter

# Clean up temporary files
rm -rf "${tmp_dir}"
