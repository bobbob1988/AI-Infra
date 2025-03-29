terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
resource "aws_vpc" "emr_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "emr-vpc"
  }
}

# Subnet Configuration
resource "aws_subnet" "emr_subnet" {
  vpc_id                  = aws_vpc.emr_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "emr-subnet"
  }
}

# Security Group
resource "aws_security_group" "emr_sg" {
  name        = "emr-security-group"
  description = "Security group for EMR cluster"
  vpc_id      = aws_vpc.emr_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6006
    to_port     = 6006
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8501
    to_port     = 8501
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "emr-sg"
  }
}

# S3 Bucket for ML Data and Models
resource "aws_s3_bucket" "ml_bucket" {
  bucket = "ai-infrastructure-ml-data-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# EMR Cluster
resource "aws_emr_cluster" "cluster" {
  name          = "ai-infrastructure"
  release_label = "emr-6.10.0"
  applications  = [
    "Spark",
    "JupyterHub",
    "JupyterEnterpriseGateway",
    "TensorFlow",
    "MXNet",
    "PyTorch",
    "Horovod",
    "Ganglia"
  ]

  ec2_attributes {
    subnet_id                         = aws_subnet.emr_subnet.id
    emr_managed_master_security_group = aws_security_group.emr_sg.id
    emr_managed_slave_security_group  = aws_security_group.emr_sg.id
    instance_profile                  = aws_iam_instance_profile.emr_profile.arn
  }

  master_instance_group {
    instance_type = "m5.2xlarge"
    ebs_config {
      size                 = 100
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  core_instance_group {
    instance_type  = "m5.2xlarge"
    instance_count = 2
    ebs_config {
      size                 = 100
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  tags = {
    Name = "ai-infrastructure"
  }

  configurations_json = jsonencode([
    {
      Classification = "spark-defaults"
      Properties = {
        "spark.executor.memory" = "16g"
        "spark.executor.cores"  = "4"
        "spark.driver.memory"   = "16g"
        "spark.driver.cores"    = "4"
      }
    },
    {
      Classification = "yarn-site"
      Properties = {
        "yarn.nodemanager.resource.memory-mb" = "32768"
        "yarn.scheduler.maximum-allocation-mb" = "32768"
      }
    }
  ])
}

# IAM Role for EMR
resource "aws_iam_role" "emr_role" {
  name = "emr_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticmapreduce.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 and SageMaker Access
resource "aws_iam_role_policy" "emr_s3_sagemaker_policy" {
  name = "emr_s3_sagemaker_policy"
  role = aws_iam_role.emr_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "sagemaker:CreateExperiment",
          "sagemaker:CreateTrial",
          "sagemaker:CreateTrialComponent",
          "sagemaker:DeleteExperiment",
          "sagemaker:DeleteTrial",
          "sagemaker:DeleteTrialComponent",
          "sagemaker:DescribeExperiment",
          "sagemaker:DescribeTrial",
          "sagemaker:DescribeTrialComponent",
          "sagemaker:ListExperiments",
          "sagemaker:ListTrials",
          "sagemaker:ListTrialComponents",
          "sagemaker:UpdateExperiment",
          "sagemaker:UpdateTrial",
          "sagemaker:UpdateTrialComponent"
        ]
        Resource = [
          aws_s3_bucket.ml_bucket.arn,
          "${aws_s3_bucket.ml_bucket.arn}/*",
          "arn:aws:sagemaker:${var.aws_region}:*:experiment/*",
          "arn:aws:sagemaker:${var.aws_region}:*:trial/*",
          "arn:aws:sagemaker:${var.aws_region}:*:trial-component/*"
        ]
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "emr_profile" {
  name = "emr_profile"
  role = aws_iam_role.emr_role.name
}

# Outputs
output "emr_cluster_id" {
  value = aws_emr_cluster.cluster.id
}

output "emr_master_public_dns" {
  value = aws_emr_cluster.cluster.master_public_dns
}

output "ml_data_bucket" {
  value = aws_s3_bucket.ml_bucket.id
} 