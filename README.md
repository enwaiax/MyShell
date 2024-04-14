## MyShell

```bash
bash <(curl -fsSL https://bit.ly/NinOne)
```

## Maddy email

```shell
docker volume create maddydata
docker run -d --name maddy --restart=unless-stopped \
  -e MADDY_HOSTNAME=mail.dlmu.ml -e MADDY_DOMAIN=dlmu.ml \
  -v maddydata:/data \
  -p 25:25 -p 143:143 -p 465:465 -p 587:587 -p 993:993 \
  enwaiax/maddy:latest
```

## Custom service

```shell
cat > /etc/systemd/system/plexdrive.service <<EOF
[Unit]
Description=Plexdrive
AssertPathIsDirectory=/home/gdrive
After=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/plexdrive mount \
 -c /home/.plexdrive \
 -o allow_other \
 -v 4 --refresh-interval=1m \
 --chunk-check-threads=4 \
 --chunk-load-threads=4 \
 --chunk-load-ahead=4 \
 --max-chunks=20 \
 /home/gdrive
ExecStop=/bin/fusermount -u /home/gdrive
Restart=on-abort

[Install]
WantedBy=default.target
EOF
```

## adguardhome

```shell
docker run --name adguardhome\
    --restart unless-stopped\
    -v /my/own/workdir:/opt/adguardhome/work\
    -v /my/own/confdir:/opt/adguardhome/conf\
    -p 53:53/tcp -p 53:53/udp\
    -p 443:443/udp -p 3000:3000/tcp\
    -p 853:853/tcp\
    -p 784:784/udp -p 853:853/udp -p 8853:8853/udp\
    -p 5443:5443/tcp -p 5443:5443/udp\
    -d adguard/adguardhome
```

## node_exporter
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/Chasing66/MyShell/main/install_node_exportor.sh)"

bash <(curl -fsSL https://raw.githubusercontent.com/Chasing66/MyShell/main/install_node_exportor.sh)
```

