#!/bin/bash

# slack hook to notify me when the deploy starts running
# curl -X POST -H 'Content-type: application/json' --data '{"text":"Keycloak deploy starting..."}' https://hooks.slack.com/services/[REMOVED]

# update the server and install the things we'll need
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install openjdk-21-jdk unzip postgresql net-tools nginx certbot python3-certbot-nginx -y

# set the hostname
sudo hostnamectl set-hostname ${server_name}
sudo sed -i "s/127.0.1.1.*/127.0.1.1 ${server_name}/" /etc/hosts

# install keycloak
cd /opt
sudo wget https://github.com/keycloak/keycloak/releases/download/26.2.4/keycloak-26.2.4.zip
sudo unzip keycloak-26.2.4.zip
sudo mv keycloak-26.2.4 keycloak
sudo rm keycloak-26.2.4.zip
sudo useradd keycloak --system --no-create-home --user-group
sudo chown -R keycloak:keycloak /opt/keycloak
cd /opt/keycloak/bin
sudo mkdir /var/log/keycloak
sudo chown keycloak:keycloak /var/log/keycloak

sudo -u postgres psql <<EOSQL
CREATE DATABASE keycloak;
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
ALTER DATABASE keycloak OWNER TO keycloak;
EOSQL

sudo -u keycloak tee /opt/keycloak/conf/keycloak.conf > /dev/null <<'EOCONFIG'
db=postgres
db-url=jdbc:postgresql://127.0.0.1:5432/keycloak
db-username=keycloak
db-password=password
bootstrap-admin-username=temp-admin
bootstrap-admin-password=password
hostname=${server_name}.${dns_zone}
http-enabled=true
proxy-headers=xforwarded
EOCONFIG

# create a service for keycloak
sudo tee /etc/systemd/system/keycloak.service > /dev/null <<'EOSERVICE'
[Unit]
Description=Keycloak Service (with config file)
After=network.target postgresql.service

[Service]
Type=simple
User=keycloak
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start
Environment=KEYCLOAK_LOGLEVEL=INFO

StandardOutput=append:/var/log/keycloak/keycloak.log
StandardError=append:/var/log/keycloak/keycloak.err
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOSERVICE

sudo systemctl daemon-reload
sudo systemctl enable keycloak
sudo systemctl start keycloak

# setup the nginx proxy for keycloak
sudo tee /etc/nginx/sites-available/keycloak > /dev/null <<'EONGINX'
server {
    listen 80;
    server_name ${server_name}.${dns_zone};

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port 443;
    }
}
EONGINX

sudo ln -s /etc/nginx/sites-available/keycloak /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# wait a bit to make sure the dns name has been put in place (there are better ways to do this...but, you know...)
sleep 90

# get our SSL cert
# note: if you're doing a lot of testing, use --staging to avoid being throttled
if [ "${certbot_staging}" = "true" ]; then
    sudo certbot --nginx -d ${server_name}.${dns_zone} --non-interactive --agree-tos --email ${certbot_email} --redirect --staging
else
    sudo certbot --nginx -d ${server_name}.${dns_zone} --non-interactive --agree-tos --email ${certbot_email} --redirect
fi

# perform some keycloak tasks - set the initial admin password; create a secondary admin
cd /opt/keycloak/bin
sudo -u keycloak ./kcadm.sh config credentials --server http://localhost:8080 --realm master --user temp-admin --password password --config ./kcadm.config
sudo -u keycloak ./kcadm.sh create users -s username=admin -s enabled=true --config ./kcadm.config
sudo -u keycloak ./kcadm.sh set-password --username admin --new-password password --config ./kcadm.config
sudo -u keycloak ./kcadm.sh add-roles --uusername admin --rolename admin --config ./kcadm.config
sudo -u keycloak ./kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password password --config ./kcadm.config

# slack hook to notify me when the deploy is finished
# curl -X POST -H 'Content-type: application/json' --data '{"text":"Keycloak deploy finished: https://keycloak.foxlab.ca"}' https://hooks.slack.com/services/[REMOVED]
