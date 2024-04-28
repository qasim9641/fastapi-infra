provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical's AWS owner ID
}

resource "aws_key_pair" "deployer-key" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKjIjwqWplnaH9sX130e7YqhII0Lt5jUT2gkVckwkR9IsZ3hQ/cTw6L3sMjpzrqjEqGDZ8K1O65zqxPkeuby4gnhye/YUVP11wgVFh8gyzl7Lat8kwoTV/nyCTargEyeUqrA1VUXVnttSEnEMPABv49m5F+AYUrnOmBtbDa8U1x6qKgviLnq9vG2OZ37hWdGNUYRoya2sGFNmV74gTUXLi11Rx7MMeFBAqbgt+hKrYgyyzGJ3xCzXhLN1o46fMuYSLciiHgOAG8YNG/gQGzDnPVoTi8t9ZTb1WGkC81lhSwzPU650HjTB8tomn7Dq7SntG/orBFOZ3qyMnGMvQ9JMkKO+t1avt9R1w6WbO2rkcOLtqltZ7f4dAlIHw3SS9AY4iKI3i2OMcHvv89IF3vOrkjDqii9DxNq1g7Ub2CWoA/p/ZRky99MEw5DeZVLSUdoGJXuz4LBS9hgKXBiZ/kVpJF07OjeoUQ7EJ/pHei0AzCWzZ7UHxPbAh5w4dxchlt5ofUWRyfjvyDlGunUrq5H42yuv5zMEl1w/UoG7do1rsUX5QRShuhVv8R9VUtT+N5ai0wjLbIpOP25/ubYEkw1rHUqBouCjPzBBY2+MQ6CecM649B6x1/Dk0IKcOy0HObQBUARFqRr34Rqhi49ezIu8Vpz+n+XVdc+c4kwdKQ+25EQ== qasim964@gmail.com"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "fastapi_sg" {
  name        = "fastapi-security-group"
  description = "Security group for FastAPI EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"

  name           = "FastAPI-Fibonacci-App"
  ami            = data.aws_ami.ubuntu.id
  instance_type  = "t2.small"
  key_name       = "deployer-key"  # Ensure you have this key or create it
  vpc_security_group_ids = [aws_security_group.fastapi_sg.id]
  subnet_id      = module.vpc.public_subnets[0]
  associate_public_ip_address = true

  user_data = <<-EOF
                #!/bin/bash
                apt update
                apt install -y python3-pip
                apt install -y python3-pip git
                pip3 install fastapi uvicorn
                git clone https://github.com/qasim9641/fastapi-app.git /home/ubuntu/fastapi-app
                nohup uvicorn app:app --host 0.0.0.0 --port 80 &
                EOF

  tags = {
    Terraform = "true"
    Project   = "FastAPI Fibonacci Checker"
  }
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
