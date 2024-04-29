provider "aws" {
  region = var.region
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



resource "aws_iam_role" "ec2_role" {
  name = "EC2_ECR_Access_Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "EC2_ECR_Profile"
  role = aws_iam_role.ec2_role.name
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
  key_name       = var.key_name  
  vpc_security_group_ids = [aws_security_group.fastapi_sg.id]
  subnet_id      = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
                #!/bin/bash
                apt update
                apt install -y awscli docker.io
                systemctl start docker
                systemctl enable docker
                aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${var.ecr_registry_url}
                docker pull ${var.ecr_registry_url}/${var.repository_name}:${var.image_tag}
                docker run -d --name ${var.container_name} -p 80:80 ${var.ecr_registry_url}/${var.repository_name}:${var.image_tag}
                EOF

  tags = {
    Terraform = "true"
    Project   = "FastAPI Fibonacci Checker"
  }
}

output "instance_public_ip" {
  value = module.ec2_instance.public_ip
}
