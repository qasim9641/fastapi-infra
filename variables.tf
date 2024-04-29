variable "ecr_registry_url" {
  description = "The URL of the ECR registry"
  type        = string
}

variable "repository_name" {
  description = "The name of the ECR repository"
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image to pull"
  type        = string
}

variable "container_name" {
  description = "The name of the Docker container"
  type        = string
}

variable "key_name" {
  description = "The key pair name to be used for the EC2 instance"
  type        = string
}

variable "region" {
  description = "The AWS region in which resources will be created"
  default     = "us-east-1"
  type        = string
}
