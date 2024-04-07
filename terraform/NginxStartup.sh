#!/bin/bash
set -e
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
apt-get install -y awscli jq

mkdir -p /etc/nginx/ssl/derektank.com
aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r '.NGINXSSLCert | gsub("\\\\n";"\n")' > /etc/nginx/ssl/derektank.com/fullchain.pem
aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r '.NGINXSSLPrivkey | gsub("\\\\n";"\n")' > /etc/nginx/ssl/derektank.com/privkey.pem
chmod 600 /etc/nginx/ssl/derektank.com/*

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
