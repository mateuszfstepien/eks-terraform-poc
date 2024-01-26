#inputs from vpc module
variable "aws_public_subnet" {}
variable "vpc_id" {}

variable "cluster_name" {
  type = string
}

variable "endpoint_private_access" {
  type        = bool
  description = "indicates whether or not the Amazon EKS private API server endpoint is enabled. Default is false"
}

variable "endpoint_public_access" {
  type        = bool
  description = "indicates whether or not the Amazon EKS public API server endpoint is enabled. Default is true"
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow public access to the Amazon EKS public API server endpoint."
}

variable "node_group_name" {
  type        = string
  description = "The unique name to give to the node group."
}

variable "scaling_desired_size" {
  type        = number
  description = "The desired number of worker nodes."
}
variable "scaling_max_size" {
  type        = number
  description = "The maximum number of worker nodes."
}
variable "scaling_min_size" {
  type        = number
  description = "The minimum number of worker nodes."
}

variable "instance_types" {
  type        = list(string)
  description = "Set of instance types associated with the EKS Node Group."
}

variable "key_pair" {
  type        = string
  description = "The key pair to use for SSH access to the EC2 instances. Without a key pair, SSH access is not possible."
}

variable "restrict_ssh_node_access" {
  type        = bool
  default     = false
  description = "Restrict SSH access to worker nodes only to node group security group."
}

variable "deploy_wordpress" {
  type        = bool
  default     = false
  description = "deploy wordpress helm chart or not"
}

variable "wordpress_namespace" {
  type        = string
  default     = "wordpress"
  description = "namespace for wordpress helm chart (if deployed)"
}
