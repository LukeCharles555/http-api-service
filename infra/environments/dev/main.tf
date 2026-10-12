terraform {
  required_version = ">= 1.6, < 2.0"

  backend "s3" {
    bucket       = "luke-infra-demo-tfstate-258562790897"
    key          = "dev/terraform.tfstate"
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
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

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
  environment        = "dev"
  bundle_path        = abspath("${path.root}/../../../api/dist/handler.cjs")
  memory_size        = 128
  timeout            = 5
  log_retention_days = 7
  log_level          = "debug"
}

output "function_name" {
  value = module.api.function_name
}

output "api_url" {
  value = module.api.api_url
}