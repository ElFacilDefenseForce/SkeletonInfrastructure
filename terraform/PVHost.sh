#!/bin/bash
set -e
apt-get update
apt-get install -y git
apt-get install -y curl
apt-get install -y awscli jq
apt-get install -y python3.10 python3-pip python3.10-venv
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1
pip3 install poetry

$PVDir = /opt/pet-vae
git clone https://github.com/dthuff/pet-vae.git $PVDir
cd $PVDir
poetry install --no-root

apt-get install -y nginx
systemctl start nginx
systemctl enable nginx

NGINX_CONF="/etc/nginx/sites-available/default"
echo "# Port 80 Redirect" > $NGINX_CONF

echo "server {" >> $NGINX_CONF
echo "    listen 80;" >> $NGINX_CONF
echo "    server_name derektank.com;" >> $NGINX_CONF
echo "    return 301 https://www.derektank.com\$request_uri;" >> $NGINX_CONF
echo "}" >> $NGINX_CONF
echo "" >> $NGINX_CONF

echo "# Upgrade to HTTPS" >> $NGINX_CONF
echo "server {" >> $NGINX_CONF
echo "    listen 80;" >> $NGINX_CONF
echo "    server_name www.derektank.com taiga.derektank.com;" >> $NGINX_CONF
echo "    return 301 https://\$server_name\$request_uri;" >> $NGINX_CONF
echo "}" >> $NGINX_CONF
echo "" >> $NGINX_CONF

echo "# Personal Website Server Block" >> $NGINX_CONF
echo "server {" >> $NGINX_CONF
echo "    listen 443 ssl;" >> $NGINX_CONF
echo "    server_name www.derektank.com;" >> $NGINX_CONF
echo "" >> $NGINX_CONF
echo "    ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;" >> $NGINX_CONF
echo "    ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;" >> $NGINX_CONF
echo "" >> $NGINX_CONF
echo "    location / {" >> $NGINX_CONF
echo "        proxy_pass https://ec2-44-213-132-37.compute-1.amazonaws.com;" >> $NGINX_CONF
echo "        proxy_set_header Host \$host;" >> $NGINX_CONF
echo "        proxy_set_header X-Real-IP \$remote_addr;" >> $NGINX_CONF
echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> $NGINX_CONF
echo "        proxy_set_header X-Forwarded-Proto \$scheme;" >> $NGINX_CONF
echo "    }" >> $NGINX_CONF
echo "}" >> $NGINX_CONF
echo "" >> $NGINX_CONF

echo "# Taiga Web App Server Block" >> $NGINX_CONF
echo "server {" >> $NGINX_CONF
echo "    listen 443 ssl;" >> $NGINX_CONF
echo "    server_name taiga.derektank.com;" >> $NGINX_CONF
echo "" >> $NGINX_CONF
echo "    ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;" >> $NGINX_CONF
echo "    ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;" >> $NGINX_CONF
echo "" >> $NGINX_CONF
echo "    location / {" >> $NGINX_CONF
echo "        proxy_pass https://ec2-44-213-132-37.compute-1.amazonaws.com;" >> $NGINX_CONF
echo "        proxy_set_header Host \$host;" >> $NGINX_CONF
echo "        proxy_set_header X-Real-IP \$remote_addr;" >> $NGINX_CONF
echo "        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;" >> $NGINX_CONF
echo "        proxy_set_header X-Forwarded-Proto \$scheme;" >> $NGINX_CONF
echo "    }" >> $NGINX_CONF
echo "}" >> $NGINX_CONF

nginx -t
sudo systemctl restart nginx
