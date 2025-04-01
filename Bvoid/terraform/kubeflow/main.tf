terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# EKS Cluster
resource "aws_eks_cluster" "kubeflow" {
  name     = "kubeflow-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.24"

  vpc_config {
    subnet_ids = local.subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# EKS Node Group
resource "aws_eks_node_group" "kubeflow" {
  cluster_name    = aws_eks_cluster.kubeflow.name
  node_group_name = "kubeflow-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = local.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 1
  }

  instance_types = ["g4dn.xlarge"]  # GPU instance for ML workloads

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}

# S3 Bucket for Kubeflow Artifacts
resource "aws_s3_bucket" "kubeflow_artifacts" {
  bucket = "kubeflow-artifacts-${random_string.bucket_suffix.result}"
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for EKS Nodes
resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for S3 and SageMaker Access
resource "aws_iam_role_policy" "eks_s3_sagemaker_policy" {
  name = "eks_s3_sagemaker_policy"
  role = aws_iam_role.eks_nodes.id

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
          "sagemaker:UpdateTrialComponent",
          "sagemaker:CreateModel",
          "sagemaker:CreateEndpoint",
          "sagemaker:CreateEndpointConfig",
          "sagemaker:CreateTrainingJob",
          "sagemaker:CreateHyperParameterTuningJob"
        ]
        Resource = [
          aws_s3_bucket.kubeflow_artifacts.arn,
          "${aws_s3_bucket.kubeflow_artifacts.arn}/*",
          "arn:aws:sagemaker:${var.aws_region}:*:experiment/*",
          "arn:aws:sagemaker:${var.aws_region}:*:trial/*",
          "arn:aws:sagemaker:${var.aws_region}:*:trial-component/*",
          "arn:aws:sagemaker:${var.aws_region}:*:model/*",
          "arn:aws:sagemaker:${var.aws_region}:*:endpoint/*",
          "arn:aws:sagemaker:${var.aws_region}:*:endpoint-config/*",
          "arn:aws:sagemaker:${var.aws_region}:*:training-job/*",
          "arn:aws:sagemaker:${var.aws_region}:*:hyper-parameter-tuning-job/*"
        ]
      }
    ]
  })
}

# IAM Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# Outputs
output "cluster_endpoint" {
  value = aws_eks_cluster.kubeflow.endpoint
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.kubeflow.vpc_config[0].cluster_security_group_id
}

output "cluster_name" {
  value = aws_eks_cluster.kubeflow.name
}

output "kubeflow_artifacts_bucket" {
  value = aws_s3_bucket.kubeflow_artifacts.id
} 