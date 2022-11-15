variable "region" {
  type = string
  default = "eu-central-1"
}
variable "truststore_pem" {
  type = string
}
variable "client_cert" {
  type = string
}
variable "client_cert_key" {
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