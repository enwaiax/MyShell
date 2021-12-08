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
