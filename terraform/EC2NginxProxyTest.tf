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
    values = ["*cloudimg-nginx-ubuntu-server2204v1.0.0-27-09-2023-104569e0-3ced-43b1-a24b-b4fa278d0377*"]
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
  vpc_security_group_ids  = ["sg-09996be9bf1979f6c"]

  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /etc/nginx/ssl/derektank.com
    sudo systemctl restart nginx
    EOF


  tags = {
    Name = "NGINXProxy"
  }
}

output "nginx_instance_ip" {
  value = aws_instance.nginx_instance.public_ip
}
