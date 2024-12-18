resource "aws_iam_role" "karpenter_node_role" {
  name = "karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = "https://charts.karpenter.sh/"
  chart      = "karpenter"
  version    = var.karpenter_version

  create_namespace = true

  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "aws.defaultInstanceProfile"
    value = aws_iam_role.karpenter_node_role.name
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}


resource "kubernetes_manifest" "karpenter_provisioner" {
  manifest = {
    "apiVersion" = "karpenter.sh/v1alpha5"
    "kind"       = "Provisioner"
    "metadata" = {
      "name" = "default"
    }
    "spec" = {
      "requirements" = [
        { "key" = "node.kubernetes.io/instance-type", "operator" = "In", "values" = ["t4g.large", "m6g.large"] },
        { "key" = "karpenter.sh/capacity-type", "operator" = "In", "values" = ["spot"] }
      ]
      "limits" = { "resources" = { "cpu" = "100", "memory" = "500Gi" } }
    }
  }

  depends_on = [helm_release.karpenter]
}
