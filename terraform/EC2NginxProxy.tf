# Review Feedback: https://chat.openai.com/share/c5a3fb92-715c-42fb-b923-805e977dc236

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

data "aws_ami" "nginx_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*NGINX on Ubuntu Server 22.04 with Support by cloudimg*"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  owners = ["aws-marketplace"]
}

data "aws_iam_instance_profile" "ssl_cert_access_profile" {
  name = "SSLCertAccessProfile"
}


resource "aws_instance" "nginx_instance" {
  ami           = data.aws_ami.nginx_ami.id
  instance_type = "t3.micro"
  key_name      = "Shadrach"
  iam_instance_profile = data.aws_iam_instance_profile.ssl_cert_access_profile.name

  user_data = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt-get install -y nginx
    sudo apt-get install -y awscli jq
    mkdir -p /etc/nginx/ssl/derektank.com
    aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r .certificate > /etc/nginx/ssl/fullchain.pem
    aws secretsmanager get-secret-value --secret-id derektank.com_SSL --region us-west-2 --query SecretString --output text | jq -r .privateKey > /etc/nginx/ssl/privkey.pem
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

    #/* Taiga Web App Server Block
    #    server {
    #      listen 443 ssl;
    #      server_name taiga.derektank.com;
    #  
    #      ssl_certificate /etc/nginx/ssl/derektank.com/fullchain.pem;
    #      ssl_certificate_key /etc/nginx/ssl/derektank.com/privkey.pem;
    #  
    #      location / {
    #        proxy_pass http://<Another-EC2-Instance-IP>;
    #        proxy_set_header Host \$host;
    #        proxy_set_header X-Real-IP \$remote_addr;
    #        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    #        proxy_set_header X-Forwarded-Proto \$scheme;
    #      }
    #    }
    #*/
    EOT
    sudo systemctl restart nginx
    EOF


  tags = {
    Name = "NGINXProxy"
  }
}

output "nginx_instance_ip" {
  value = aws_instance.nginx_instance.public_ip
}
