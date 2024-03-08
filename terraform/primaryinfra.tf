provider "aws" {
  region  = "us-west-2"
  version = "~> 3.0"
}

data "aws_ami" "jenkins_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*Jenkins - Ubuntu 22 x86_64*"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  owners = ["aws-marketplace"]
}

resource "aws_instance" "jenkins_instance" {
  ami           = data.aws_ami.jenkins_ami.id
  instance_type = "c4.large"
  key_name      = var.key_name

  tags = {
    Name = "Greenhill"
  }
}

output "jenkins_instance_ip" {
  value = aws_instance.jenkins_instance.public_ip
}