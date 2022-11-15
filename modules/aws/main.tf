terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

// cert bucket
resource "aws_s3_bucket" "certs" {
  bucket = "fc-client-certificates"

  tags = {
    Name        = "Client Certificates"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "certs" {
  bucket = aws_s3_bucket.certs.id
  acl    = "private"
}

resource "aws_s3_object" "truststore_pem" {
  bucket = aws_s3_bucket.certs.id
  key = "truststore.pem"
  content = var.truststore_pem
}


// Login Lambda
data "archive_file" "lambda_login" {
  type = "zip"

  source_dir  = "${path.module}/src/functions/login"
  output_path = "${path.module}/src/functions/login.zip"
}


resource "aws_lambda_function" "lambda_login" {
  function_name = "login"

  filename = "${path.module}/src/functions/login.zip"

  runtime = "nodejs12.x"
  handler = "login.handler"

  source_code_hash = data.archive_file.lambda_login.output_base64sha256

  role = aws_iam_role.lambda_exec.arn

  tags = {
    "project" = "poc-auth0-customdb-client-certs"
    "type" = "poc"
    "company" = "okta"
  }
}

resource "aws_cloudwatch_log_group" "lambda_login" {
  name = "/aws/lambda/${aws_lambda_function.lambda_login.function_name}"

  retention_in_days = 1

  tags = {
    "project" = "poc-auth0-customdb-client-certs"
    "type" = "poc"
    "company" = "okta"
  }
}
// Sign Up Lambda

data "archive_file" "lambda_signup" {
  type = "zip"

  source_dir  = "${path.module}/src/functions/signup"
  output_path = "${path.module}/src/functions/signup.zip"
}


resource "aws_lambda_function" "lambda_signup" {
  function_name = "signup"

  filename = "${path.module}/src/functions/signup.zip"

  runtime = "nodejs12.x"
  handler = "signup.handler"

  source_code_hash = data.archive_file.lambda_signup.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
  tags = {
    "project" = "poc-auth0-customdb-client-certs"
    "type" = "poc"
    "company" = "okta"
  }
}

resource "aws_cloudwatch_log_group" "lambda_signup" {
  name = "/aws/lambda/${aws_lambda_function.lambda_signup.function_name}"

  retention_in_days = 1

  tags = {
    "project" = "poc-auth0-customdb-client-certs"
    "type" = "poc"
    "company" = "okta"
  }
}

// Generic IAM Role

resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })

  tags = {
    "project" = "poc-auth0-customdb-client-certs"
    "type" = "poc"
    "company" = "okta"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "auth0-customdb-apigw"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  disable_execute_api_endpoint = true
}

resource "aws_api_gateway_domain_name" "custom_domain" {
  regional_certificate_arn = var.certificate_arn
  domain_name = var.custom_domain
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  security_policy = "TLS_1_2"
  mutual_tls_authentication {
    truststore_uri = "s3://${aws_s3_bucket.certs.id}/${aws_s3_object.truststore_pem.id}"
  }
}

resource "aws_route53_record" "custom_domain" {
  name = aws_api_gateway_domain_name.custom_domain.domain_name
  type = "A"
  zone_id = var.zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.custom_domain.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain.regional_zone_id
  }
}

resource "aws_api_gateway_base_path_mapping" "api_base" {
  api_id      = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.example.stage_name
  domain_name = aws_api_gateway_domain_name.custom_domain.domain_name
}

// login
resource "aws_api_gateway_resource" "login_proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "login"
}

resource "aws_api_gateway_method" "login_proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.login_proxy.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_method.login_proxy.resource_id}"
  http_method = "${aws_api_gateway_method.login_proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda_login.invoke_arn}"
}
// signup
resource "aws_api_gateway_resource" "signup_proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "signup"
}

resource "aws_api_gateway_method" "signup_proxy" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.signup_proxy.id}"
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_method.signup_proxy.resource_id}"
  http_method = "${aws_api_gateway_method.signup_proxy.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda_signup.invoke_arn}"
}





// deployment
resource "aws_api_gateway_stage" "example" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  depends_on = [
      aws_api_gateway_integration.login_lambda,
      aws_api_gateway_integration.signup_lambda,
  ]
  stage_name = "dev"
  deployment_id = aws_api_gateway_deployment.dev_stage.id
 
}
resource "aws_api_gateway_deployment" "dev_stage" {
  depends_on = [
    aws_api_gateway_integration.login_lambda,
    aws_api_gateway_integration.signup_lambda,
  ]

  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.lambda_login,
      aws_lambda_function.lambda_signup
    ]
  }
}

resource "aws_lambda_permission" "apigw_login" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_login.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
resource "aws_lambda_permission" "apigw_signup" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_signup.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}






# store certificate in parameter store as it is too big for configuration parameter in auth0
resource "aws_ssm_parameter" "certificate" {
  name        = "/auth0-client-cert/cert"
  description = "API Cert for Auth0"
  type        = "SecureString"
  value       = var.client_cert

  tags = {
    environment = "production"
  }
}
resource "aws_ssm_parameter" "cert_key" {
  name        = "/auth0-client-cert/key"
  description = "API Cert Private Key for Auth0"
  type        = "SecureString"
  value       = var.client_cert_key

  tags = {
    environment = "production"
  }
}

# create iam user that is allowed to read the credential
resource "aws_iam_user" "auth0" {
  name = "auth0"

}

resource "aws_iam_access_key" "auth0" {
  user = aws_iam_user.auth0.name
}

resource "aws_iam_user_policy" "auth0_ro" {
  name = "auth0-ssm"
  user = aws_iam_user.auth0.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
        ]
        Effect   = "Allow"
        Resource = ["${aws_ssm_parameter.certificate.arn}", "${aws_ssm_parameter.cert_key.arn}"]
      },
    ]
  })
}