# helm chart for metrics-server needed for autoscaling
# using pre-downloaded chart to have self-contained packaged

resource "helm_release" "metric_server" {
  name      = "metric-server"
  chart     = "../helm/metrics-server-3.11.0.tgz"
  namespace = "kube-system"
  depends_on = [
    aws_eks_cluster.sandboxing,
    aws_eks_node_group.sandboxing,
  ]
}

# helm chart for wordpress
# deployed by default, but can be disabled by setting deploy_wordpress to false
# can be then adjusted and deployed with helm upgrade/install command

resource "helm_release" "wordpress" {
  count            = var.deploy_wordpress ? 1 : 0
  name             = "my-wordpress"
  chart            = "../helm/wordpress-0.1.1.tgz"
  namespace        = var.wordpress_namespace
  create_namespace = true
  depends_on = [
    aws_eks_cluster.sandboxing,
    aws_eks_node_group.sandboxing,
    helm_release.metric_server
  ]
  values = [
    file("../helm/values.yaml"),
  ]
}
