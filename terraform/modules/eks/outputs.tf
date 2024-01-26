output "endpoint" {
  value = aws_eks_cluster.sandboxing.endpoint
}
output "cluster_id" {
  value = aws_eks_cluster.sandboxing.id
}
output "cluster_endpoint" {
  value = aws_eks_cluster.sandboxing.endpoint
}
output "cluster_name" {
  value = aws_eks_cluster.sandboxing.name
}
output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.sandboxing.certificate_authority[0].data
}
