output "login_lambda_functionName" {
  description = "Name of the Login Lambda function."

  value = aws_lambda_function.lambda_login.function_name
}
output "signup_lambda_functionName" {
  description = "Name of the Signup Lambda function."
  value = aws_lambda_function.lambda_signup.function_name
}

output "api_basepath" {
    description = "base path to access the api"
    value = aws_api_gateway_deployment.dev_stage.invoke_url
}
output "cert_param_name" {
  description = "paramter that stores the certificate"
  value = aws_ssm_parameter.certificate.name
}

output "cert_key_param_name" {
  description = "paramter that stores the certificate key"
  value = aws_ssm_parameter.cert_key.name
}
output "cert_read_access_key_id" {
    value = aws_iam_access_key.auth0.id
    sensitive = true
}
output "cert_read_secret_access_key" {
    value = aws_iam_access_key.auth0.secret
    sensitive = true
}