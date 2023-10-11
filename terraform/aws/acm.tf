resource "tls_private_key" "jed_rearc_quest" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "jed_rearc_quest" {
  private_key_pem = tls_private_key.jed_rearc_quest.private_key_pem

  subject {
    common_name  = "esserlabs.com"
    organization = "Esser Labs"
  }

  validity_period_hours = 168

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.jed_rearc_quest.private_key_pem
  certificate_body = tls_self_signed_cert.jed_rearc_quest.cert_pem
}
