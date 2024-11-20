# -------------------------------------------------- #
# HydroServer AWS App Runner Service                 #
# -------------------------------------------------- #

resource "aws_apprunner_service" "hydroserver_api" {
  service_name      = "hydroserver-api-${var.instance}"
  
  instance_configuration {
    instance_role_arn = aws_iam_role.app_runner_service_role.arn
  }

  source_configuration {
    image_repository {
      image_identifier = "${aws_ecr_repository.hydroserver_api_repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
        runtime_environment_secrets = {
          DATABASE_URL         = data.aws_secretsmanager_secret.database_url.arn
          SECRET_KEY           = data.aws_secretsmanager_secret.secret_key.arn
        }
        runtime_environment_variables = {
          DEPLOYED             = "True"
          DEPLOYMENT_BACKEND   = "aws"
          # STORAGE_BUCKET       = aws_s3_bucket.hydroserver_storage_bucket.bucket
          # SMTP_URL             = aws_secretsmanager_secret.hydroserver_smtp_url.arn
          # ACCOUNTS_EMAIL       = aws_secretsmanager_secret.hydroserver_oauth_google.arn
          PROXY_BASE_URL       = "https://www.example.com"
          # ALLOWED_HOSTS        = ""
          # OAUTH_GOOGLE         = aws_secretsmanager_secret.hydroserver_oauth_google.arn
          # OAUTH_ORCID          = aws_secretsmanager_secret.hydroserver_oauth_orcid.arn
          # OAUTH_HYDROSHARE     = aws_secretsmanager_secret.hydroserver_oauth_hydroshare.arn
          # DEBUG                = ""
        }
      }
    }

    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_access_role.arn
    }
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = false
    }

    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.hydroserver_vpc_connector.arn
    }
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/admin/"
    interval = 20
    timeout  = 5
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

data "aws_vpc" "hydroserver_vpc" {
  filter {
    name   = "tag:Name"
    values = ["hydroserver-${var.instance}"]
  }
}

data "aws_subnet_ids" "hydroserver_private_subnets" {
  vpc_id = data.aws_vpc.hydroserver_vpc.id
}

resource "aws_apprunner_vpc_connector" "hydroserver_vpc_connector" {
  vpc_connector_name = "hydroserver-api-vpc-connector-${var.instance}"
  subnets         = data.aws_subnet_ids.hydroserver_private_subnets.ids
}

data "aws_secretsmanager_secret" "database_url" {
  name = "hydroserver-database-url-${var.instance}"
}

data "aws_secretsmanager_secret" "secret_key" {
  name = "hydroserver-api-secret-key-${var.instance}"
}

# -------------------------------------------------- #
# IAM Roles for App Runner Service                   #
# -------------------------------------------------- #

resource "aws_iam_role" "app_runner_service_role" {
  name = "hydroserver-api-instance-role-${var.instance}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "tasks.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_runner_service_policy" {
  name = "hydroserver-api-secrets-access-policy-${var.instance}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = [
          data.aws_secretsmanager_secret.database_url.arn,
          data.aws_secretsmanager_secret.secret_key.arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_service_policy_attachment" {
  name       = "hydroserver-api-secrets-policy-attachment-${var.instance}"
  policy_arn = aws_iam_policy.app_runner_service_policy.arn
  roles      = [aws_iam_role.app_runner_service_role.name]
}

resource "aws_iam_role" "app_runner_access_role" {
  name = "hydroserver-api-access-role-${var.instance}"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "app_runner_ecr_access_policy" {
  name = "hydroserver-api-ecr-access-policy-${var.instance}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_ecr_access_policy_attachment" {
  name       = "hydroserver-api-ecr-access-policy-attachment-${var.instance}"
  policy_arn = aws_iam_policy.app_runner_ecr_access_policy.arn
  roles      = [aws_iam_role.app_runner_access_role.name]
}
