# Project Name: FastAPI Fibonacci Checker

## Description
This project deploys a FastAPI application on AWS infrastructure using Terraform. The application is containerized and hosted using Amazon EC2 instances with an ECR backend for Docker image storage.

## Prerequisites
Before you begin, ensure you have the following installed:
- Terraform cloud set up
- Terraform CLI
- 

## Setup
 AWS Credentials
 Ensure your AWS credentials are configured in Terraform cloud. This can be done through the AWS CLI:

Terrform cloud   

terraform login 

Create a terraform.tfvars file with the necessary configurations as follows:
hcl

ecr_registry_url  = "<ecr_registry_url>"
repository_name   = "<repository_name>"
image_tag         = "latest"
container_name    = "fastapi-container"
key_name          = "<key_name>"


Replace the placeholders with actual values.

Run the following command to initialize Terraform, it will download the necessary providers and modules:

terraform init


## Deployment

To deploy the application, run the following commands:

terraform plan

Review the plan if it looks good then run

terraform apply

## Post Deployment
After the successfully deployment you will see the IP in the output section. Next open your browser and use the app

<public-IP>//fibonacci/<number>


