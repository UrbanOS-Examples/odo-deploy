terraform {
  backend "s3" {
    key     = "odo"
    encrypt = true
  }
}

resource "local_file" "kubeconfig" {
  filename          = "${path.module}/outputs/kubeconfig"
  sensitive_content = data.terraform_remote_state.env_remote_state.outputs.eks_cluster_kubeconfig
}

provider "helm" {
  version = ">= 2.1"
  kubernetes {
    config_path = local_file.kubeconfig.filename
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
  namespace        = "odo"
  create_namespace = true
  wait             = false


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