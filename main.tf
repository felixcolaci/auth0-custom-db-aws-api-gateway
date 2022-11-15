module "ca" {
  source = "./modules/ca"
  custom_domain = var.custom_domain
}
module "aws" {
  source = "./modules/aws"
  truststore_pem = module.ca.truststore_pem
  client_cert = module.ca.client_cert
  client_cert_key = module.ca.client_cert_key

  # config
  zone_id = var.zone_id
  custom_domain = var.custom_domain
  certificate_arn = var.certificate_arn
}
module "auth0" {
    source = "./modules/auth0"
    # config
    auth0_domain = var.auth0_domain
    auth0_client_id = var.auth0_client_id
    auth0_client_secret = var.auth0_client_secret

    cert_param_name = module.aws.cert_param_name
    key_param_name = module.aws.cert_key_param_name
    api_basepath = var.custom_domain
    cert_read_access_key_id = module.aws.cert_read_access_key_id
    cert_read_secret_access_key = module.aws.cert_read_secret_access_key
}
