variable "auth0_domain" {
  type = string
}

variable "auth0_client_id" {
  type = string
}

variable "auth0_client_secret" {
  type = string
}

variable "zone_id" {
  type = string
  description = "Id of the aws hosted zone for the custom domain"
}
variable "custom_domain" {
  type = string
  description = "Domain name for the api gateway"
}
variable "certificate_arn" {
  type = string
  description = "arn of the certificate"
}