###### root/main.tf
module "eks" {
  source                  = "./modules/eks"
  aws_public_subnet       = module.vpc.aws_public_subnet
  vpc_id                  = module.vpc.vpc_id
  cluster_name            = "sandboxing-eks"
  endpoint_public_access  = true
  endpoint_private_access = false
  public_access_cidrs     = ["0.0.0.0/0"]
  node_group_name         = "sandboxing"
  scaling_desired_size    = 1
  scaling_max_size        = 1
  scaling_min_size        = 1
  instance_types          = ["t3.small"]
  key_pair                = "sboxing-eks"
  deploy_wordpress        = true
  wordpress_namespace     = "wordpress"

}

# module "eks-extras" {
#   source          = "./modules/eks-extras"
#   cluster_name    = module.eks.cluster_name
#   tls_certificate = module.eks.tls_certificate
# }

module "vpc" {
  source                  = "./modules/vpc"
  tags                    = "sandoboxing-vpc"
  instance_tenancy        = "default"
  vpc_cidr                = "10.223.95.0/24"
  access_ip               = "0.0.0.0/0"
  public_sn_count         = 2
  public_cidrs            = ["10.223.95.0/26", "10.223.95.64/26"]
  map_public_ip_on_launch = true
  rt_route_cidr_block     = "0.0.0.0/0"

}
