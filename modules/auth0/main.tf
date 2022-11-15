terraform {
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "0.37.1"
    }
  }
}

provider "auth0" {
  domain        = var.auth0_domain
  client_id     = var.auth0_client_id
  client_secret = var.auth0_client_secret
}

resource "auth0_connection" "custom_db" {
  name = "custom-db-client-cert"
  strategy = "auth0"
  options {
    enabled_database_customization = true
    custom_scripts = {
      login = file("${path.module}/src/login.js")
    }
    configuration = {
      "api_base" = var.api_basepath,
      "aws_key_id" = var.cert_read_access_key_id,
      "aws_secret" = var.cert_read_secret_access_key,
      "cert_name" = var.cert_param_name
      "key_name" = var.key_param_name
    }
  }
}