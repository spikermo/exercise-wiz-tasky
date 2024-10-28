/*************************************************
*                   GENERAL                      *
*************************************************/

variable "project_prefix" {
    description = "project prefix"
    type = string
    default = "ronniemoore-wiz"
}

/*************************************************
*                     APP                        *
*************************************************/

variable "app_name" {
  description = "The name of the application"
  default     = "tasky"
}

variable "app_dockerfile" {
  description = "The name of the Dockerfile to build the app"
  default     = "tasky.Dockerfile"
}

variable "docker_server" {
  description = "The Docker server URL for the ECR repository"
  default     = "110299713907.dkr.ecr.us-east-1.amazonaws.com"
}

locals {
  short_app_name = "${var.project_prefix}-${var.app_name}"
  full_app_uri = "${var.docker_server}/${var.project_prefix}-${var.app_name}:latest"
}

/*************************************************
*                    AWS                         *
*************************************************/

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  default     = "us-east-1"
}

variable "aws_key_name" {
  description = "The name of the key pair to use for SSH access"
  default     = "aws-ec2-ronniemoore"
}

variable "aws_ami_id" {
  description = "The AMI ID for the EC2 instance"
  default     = "ami-0dba2cb6798deb6d8"  # Ubuntu 20.04 LTS AMI ID for us-east-1
}

variable "aws_instance_type" {
  description = "The instance type for the EC2 instance"
  default     = "t2.micro"
}

data "aws_subnet" "public_subnet_1" {
  depends_on = [null_resource.wait_for_subnets]

  filter {
    name   = "tag:Name"
    values = ["${var.project_prefix}${var.vpc_suffix}-PublicSubnet01"]
  }
}

data "aws_subnet" "private_subnet_2" {
  depends_on = [null_resource.wait_for_subnets]
  filter {
    name   = "tag:Name"
    values = ["${var.project_prefix}${var.vpc_suffix}-PrivateSubnet02"]
  }
}

variable "vpc_suffix" {
  description = "suffix for VPC name"
  default     = "-stack"
}

/*************************************************
*                    EKS                         *
*************************************************/

variable "cluster_label" {
  description = "suffix for cluster name"
  default     = "-cluster"
}

# Look up EKS security group and vpc info needed for MongoDB networking
data "aws_eks_cluster" "eks" {
  depends_on = [aws_eks_cluster.eks]

  name = local.cluster_name
}

data "aws_security_group" "eks_sg" {
  depends_on = [aws_eks_cluster.eks]

  filter {
    name   = "group-name"
    values = ["eks-cluster-sg-${local.cluster_name}-*"]
  }
}

data "aws_vpc" "selected" {
  id = data.aws_subnet.public_subnet_1.vpc_id
}

locals {
  vpc_id           = data.aws_subnet.public_subnet_1.vpc_id
  vpc_cidr_block   = data.aws_vpc.selected.cidr_block
  subnet_id        = data.aws_subnet.public_subnet_1.id
  eks_sg_id        = data.aws_security_group.eks_sg.id

  cluster_name     = "${var.project_prefix}${var.cluster_label}"

  mongodb_sg_name  = "${var.project_prefix}-${var.mongodb_sg_name}"
  mongodb_uri      = "mongodb://${var.mongodb_user}:${var.mongodb_password}@${aws_instance.mongodb.private_ip}:${var.mongodb_port}/${var.mongodb_database}"
  full_bucket_name = "${var.project_prefix}${var.mongodb_suffix}${var.bucket_suffix}"
}

/*************************************************
*                    MONGO DB                    *
*************************************************/

variable "mongodb_suffix" {
  description = "MongoDB instance name suffix"
  default     = "-mongodb"
}

variable "bucket_suffix" {
  description = "The name of the S3 bucket for MongoDB backups"
  default     = "-backups"
}

variable "mongodb_port" {
  description = "The port number for MongoDB"
  default     = 27017
}

variable "mongodb_sg_name" {
  description = "The name of the MongoDB security group"
  default     = "mongodb-sg"
}

variable "mongodb_user" {
  description = "The MongoDB admin username"
  default     = "adminUser"
}

variable "mongodb_password" {
  description = "The MongoDB admin username"
  default     = "securePassword"
}

variable "mongodb_database" {
  description = "The MongoDB database name"
  default     = "admin"
}