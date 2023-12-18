data "aws_caller_identity" "requester" {
  provider = aws.requester
}

data "aws_caller_identity" "accepter" {
  provider = aws.accepter
}

data "aws_vpc" "requester" {
  provider = aws.requester

  id = var.requester_vpc_id
}

data "aws_vpc" "accepter" {
  provider = aws.accepter

  id = var.accepter_vpc_id
}
