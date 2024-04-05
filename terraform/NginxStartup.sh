#!/bin/bash
set -e
apt-get update
apt-get install -y nginx
systemctl start nginx
systemctl enable nginx
apt-get install -y awscli jq

mkdir -p /etc/nginx/ssl/derektank.com
aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r .NGINXSSLCert > /etc/nginx/ssl/derektank.com/fullchain.pem
aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r .NGINXSSLPrivkey > /etc/nginx/ssl/derektank.com/privkey.pem
chmod 600 /etc/nginx/ssl/derektank.com/*

cat <<EOT > /etc/nginx/sites-available/default
# Port 80 Redirect
server {
  listen 80;
  server_name www.derektank.com derektank.com taiga.derektank.com;
  return 301 https://\$host\$request_uri;
}
# Redirect derektank.com to www.derektank.com for HTTPS
server {
  listen 443 ssl;
  server_name derektank.com;

  ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;
  ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;

  return 301 https://www.derektank.com\$request_uri;
}
# Personal Web Site Server Block
server {
  listen 443 ssl;
  server_name www.derektank.com derektank.com;

  ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;
  ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;

  location / {
    proxy_pass http://44.213.132.37;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
# Taiga Web App Server Block
    server {
      listen 443 ssl;
      server_name taiga.derektank.com;
  
      ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;
      ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;
  
      location / {
        proxy_pass http://<Another-EC2-Instance-IP>;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
      }
    }
EOT

nginx -t
sudo systemctl restart nginx
