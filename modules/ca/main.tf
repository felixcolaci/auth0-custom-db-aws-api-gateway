terraform {
  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "4.0.4"
    }
    local = {
      source = "hashicorp/local"
      version = "2.2.3"
    }
  }
}
provider "tls" {
  # Configuration options
}

resource "tls_private_key" "ca_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  private_key_pem = tls_private_key.ca_key.private_key_pem
  validity_period_hours = 720
  allowed_uses = [ "cert_signing" ]
  is_ca_certificate = true
  subject {
    common_name = var.custom_domain
  }
}

resource "tls_private_key" "client_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "client_cert_request" {
  private_key_pem = tls_private_key.client_key.private_key_pem
  subject {
    common_name = var.custom_domain
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  cert_request_pem = tls_cert_request.client_cert_request.cert_request_pem
  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem = tls_self_signed_cert.ca_cert.cert_pem

  validity_period_hours = 168
  allowed_uses = [ "digital_signature", "client_auth" ]
}
