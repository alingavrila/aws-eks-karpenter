terraform {
  required_version = ">= 1.0"

  backend "local" {
    path = "terraform.tfstate" # Use S3 for production
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.eks_cluster.name
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}
