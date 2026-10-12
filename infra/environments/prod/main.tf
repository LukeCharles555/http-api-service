terraform {
  required_version = ">= 1.10, < 2.0"

  backend "s3" {
    bucket       = "luke-infra-demo-tfstate-258562790897"
    key          = "prod/terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "infrastructure-tech-test"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}

# Temporary workaround for the stage tag-on-create failure.
provider "aws" {
  alias  = "untagged"
  region = var.aws_region
}

module "api" {
  source = "../../modules/api"

  providers = {
    aws          = aws
    aws.untagged = aws.untagged
  }

  environment        = "prod"
  bundle_path        = abspath("${path.root}/../../../api/dist/handler.cjs")
  memory_size        = 256
  timeout            = 5
  log_retention_days = 30
  log_level          = "info"

  # Keep demo traffic limits low in both environments.
  api_rate_limit  = 1
  api_burst_limit = 2
}

output "function_name" {
  value = module.api.function_name
}

output "api_url" {
  value = module.api.api_url
}