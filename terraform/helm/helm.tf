variable "chart_root" {
  description = "Helm chart root dir"
  type        = string
  default     = "../helm"
}

resource "helm_release" "rearc_quest" {
  name       = "rearc-quest"
  chart      = "${var.chart_root}/chart"

  values = [
    file("${var.chart_root}/values/aws.yaml")
  ]
}
