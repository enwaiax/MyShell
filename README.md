# MyShell

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
