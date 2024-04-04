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
    values = ["*ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20240301*"]
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

  user_data = file("${path.module}/NginxStartup.sh")

  tags = {
    Name = "NGINXProxy"
  }
}

output "nginx_instance_ip" {
  value = aws_instance.nginx_instance.public_ip
}
