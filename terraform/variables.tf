variable "cluster_name" {
  description = "Name of the KIND cluster"
  type        = string
  default     = "hcl-hackathon"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.27.3"
}


