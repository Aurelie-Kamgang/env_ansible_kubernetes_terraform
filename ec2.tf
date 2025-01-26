terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = ""
  secret_key = ""
}


resource "aws_instance" "myec2" {
  #ami             = "ami-0d71ca6a78e324f68" # CentOS 7
  ami             = "ami-00127df3b22f11bc4" # Ubuntu
  instance_type   = "t2.medium"              # you can change this
  key_name        = "ec2_key"  # the name of your public key
  security_groups = ["franklin-sg"]

  root_block_device {
    volume_size = 100 # you can change this value
  }
}

resource "aws_security_group" "allow_http_https" {
  name        = "franklin-sg"
  description = "Allow http and https inbound traffic"

  ingress {
    description = "https from vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from vpc"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from vpc"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_eip" "lb" {
  instance = aws_instance.myec2.id
  domain   = "vpc"
  provisioner "local-exec" {
    command = "echo PUBLIC IP: ${self.public_ip} > infos_ec2.txt"
  }

}

resource "null_resource" "deploy" {

  provisioner "remote-exec" {

    connection {
      type        = "ssh"
      #user        = "centos"
      user        = "ubuntu"
      private_key = file("./ec2_key.pem")
      host        = aws_eip.lb.public_ip
    }

    inline = [
       "sudo apt update -y",
       "sudo apt install ansible -y",
       "sudo curl -sfL https://get.k3s.io | sh -",
       "sudo chmod 644 /etc/rancher/k3s/k3s.yaml",
       "mkdir -p ~/.kube",
       "cp /etc/rancher/k3s/k3s.yaml ~/.kube/config",
       "sudo chmod 600 ~/.kube/config",
       "sudo apt install python3-kubernetes -y"

    ]
  }
}
