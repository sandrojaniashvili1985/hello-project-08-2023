## Peering ##
resource "aws_vpc_peering_connection" "same_account_and_region" {
  count    = data.aws_caller_identity.requester.account_id == data.aws_caller_identity.accepter.account_id && var.accepter_region == "" ? 1 : 0
  provider = aws.requester

  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  tags = merge(
    {
      Name      = "${data.aws_vpc.requester.tags.Name}-to-${data.aws_vpc.accepter.tags.Name}"
      Component = "VPC"
    },
    var.tags
  )
}

resource "aws_vpc_peering_connection" "cross_account_or_region" {
  count    = data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id || var.accepter_region != "" ? 1 : 0
  provider = aws.requester

  vpc_id        = var.requester_vpc_id
  peer_vpc_id   = var.accepter_vpc_id
  peer_owner_id = data.aws_caller_identity.accepter.account_id
  peer_region   = var.accepter_region
  auto_accept   = false

  tags = merge(
    {
      Name      = "${data.aws_vpc.requester.tags.Name}-to-${data.aws_vpc.accepter.tags.Name}"
      Component = "VPC"
    },
    data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id ? {Side = "Requester"} : {},
    var.tags
  )
}

resource "aws_vpc_peering_connection_accepter" "cross_account_or_region" {
  count    = data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id || var.accepter_region != "" ? 1 : 0
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection.cross_account_or_region[0].id
  auto_accept               = true

  tags = merge(
    {
      Name      = "${data.aws_vpc.requester.tags.Name}-to-${data.aws_vpc.accepter.tags.Name}"
      Component = "VPC"
    },
    data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id ? {Side = "Accepter"} : {},
    var.tags
  )
}

resource "aws_vpc_peering_connection_options" "requester" {
  count    = data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id && var.accepter_region == "" ? 1 : 0
  provider = aws.requester

  # As options can't be set until the connection has been accepted
  # create an explicit dependency on the accepter.
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.cross_account_or_region[0].id

  requester {
    allow_remote_vpc_dns_resolution  = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  count    = data.aws_caller_identity.requester.account_id != data.aws_caller_identity.accepter.account_id && var.accepter_region == "" ? 1 : 0
  provider = aws.accepter

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.cross_account_or_region[0].id

  accepter {
    allow_remote_vpc_dns_resolution  = true
  }
}
