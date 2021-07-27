terraform {
  backend "s3" {
    key     = "odo"
    encrypt = true
  }
}

provider "helm" {
  version = ">= 2.1"
  debug = true
  kubernetes {
    host                   = data.terraform_remote_state.env_remote_state.outputs.eks_cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.env_remote_state.outputs.eks_cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = [
        "token", 
        "-i", 
        data.terraform_remote_state.env_remote_state.outputs.eks_cluster_name, 
        "-r", 
        var.eks_role_arn
        ]
      command     = "aws-iam-authenticator"
    }
  }
}

resource "helm_release" "odo" {
  name       = "odo"
  repository = "https://Datastillery.github.io/charts"
  # The following line exists to quickly be commented out
  # for local development.
  #repository       = "../charts"
  version          = "0.3.0"
  chart            = "odo"
  namespace        = "streaming-services"
  create_namespace = true
  wait             = false
  recreate_pods    = var.recreate_pods

  values = [
    file("${path.module}/odo.yaml")
  ]

  set {
    name  = "image.tag"
    value = var.odo_tag
  }
}

data "terraform_remote_state" "env_remote_state" {
  backend   = "s3"
  workspace = terraform.workspace

  config = {
    bucket   = var.state_bucket
    key      = "operating-system"
    region   = var.alm_region
    role_arn = var.alm_role_arn
  }
}

variable "state_bucket" {
  description = "The name of the S3 state bucket for ALM"
  default     = "scos-alm-terraform-state"
}

variable "alm_region" {
  description = "Region of ALM resources"
  default     = "us-east-2"
}

variable "alm_role_arn" {
  description = "The ARN for the assume role for ALM access"
  default     = "arn:aws:iam::199837183662:role/jenkins_role"
}

variable "odo_tag" {
  description = "The docker image tag for odo"
}

variable "recreate_pods" {
  description = "Force helm to recreate pods?"
  default     = false
}

variable "eks_role_arn" {
  description = "THe AWS ARN of the IAM role to access the EKS cluster"
  default =  "arn:aws:iam::073132350570:role/jenkins_role"
}