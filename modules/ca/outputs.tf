output "truststore_pem" {
  value = tls_self_signed_cert.ca_cert.cert_pem
}
output "client_cert" {
  value = tls_locally_signed_cert.client_cert.cert_pem
}
output "client_cert_key" {
  value = tls_private_key.client_key.private_key_pem
}
