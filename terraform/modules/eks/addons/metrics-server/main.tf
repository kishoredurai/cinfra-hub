# Metrics Server: cluster-internal resource metrics (kubectl top, HPA).
# No AWS API calls, so no IAM/pod identity wiring needed — just the chart.

resource "helm_release" "this" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = var.namespace
  version    = var.chart_version
}
