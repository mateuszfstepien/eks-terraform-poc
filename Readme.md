# EKS Terraform POC

## Description

This is a project to deploy AWS EKS cluster with metric server (for autoscaling) and dynamic storage provisioning.
It also deploys simple Helm chart for Wordpress with mysql backend db.

## Installation

Make sure you have Terraform and Helm installed and you are authenticated to AWS with priviledges to deploy EKS and it's components.

Installation requires providing AWS key pair name, so worker nodes would be available via SSH. If you dont have one, create it in AWS console and download private key in case logging into worked is needed.

```bash
git https://github.com/mateuszfstepien/eks-terraform-poc.git
cd eks-terraform-poc/terraform
```

Adjust parameters in main.tf file. At the minimum provid menioned earlier `key_pair` name, `vpc_cidr` and based on that `public_cidrs`. If you want to skip key pair, remove `remote_access` block from `aws_eks_node_group`resource in eks module. But this will remove the only option to log into worker nodes.
By default also Helm chart for wordpress will be deployed, which can be changed by setting deploy_wordpress to false.
Proceed with deployment via terraform using local state file.

```bash
terraform init
terraform plan
terraform apply
```

Manual installation of Helm chart for wordpress if you skip it in terraform deployment.

```bash
cd ../helm
helm upgrade --install my-wordpress wordpress-0.1.1.tgz --namespace=wordpress --create-namespace
```

You can make changes to chart and package it using command `helm package .` before deployment.

## Evolution of project

- Decided not to use terraform aws/eks module, and instead implement it step by step so I actually know what is going on
- Deploy VPC and EKS via Terraform
- Allow SSH connection to workers from outside designated sg (later dropped)
- Create yaml files for wordpress deployment with mysql statefulset, both on hostPath storage
- Create helm template files and package application
- Install metrcis server manually, configure autoscaler and resource limits for wordpress deployment
- Add metric server installation to Terraform with predownloaded package
- Switch wordpress service from nodePort to Loadbalancer
- Add installation of EBS CSI driver to Terraform
- Change storage for wordpress deployment to dynamic provisioning
- Change storage for mysql statefulset to dynamic provisioning
- Add namespace-wide resource quota

## Main obstacles

- Influenza
- Analysis paralysis (about initial choices and avoiding bad ones)
- Successful SSH to worker node
- Troubleshooting hostPath storage for mysql (storageclass/selector issue)
- Redeployment with different password on exisitng database (+ base64 with /n)
- Service name for mysql (namespace property vs .Release.Namespace)
- Bug in aws_eks_identity_provider_config (newer version)
- EBS CSI driver not having right permissions (still a mystery)
- mysql not working with dynamic provisioning (lost+found)
