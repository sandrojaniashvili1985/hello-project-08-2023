terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      version = "~> 3.53"
      configuration_aliases = [
        aws.requester,
        aws.accepter
      ]
    }
  }
}
