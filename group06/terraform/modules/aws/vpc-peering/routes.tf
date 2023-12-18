locals {
  requester_peering_connection_id = concat(aws_vpc_peering_connection.same_account_and_region[*].id,
                                           aws_vpc_peering_connection.cross_account_or_region[*].id)[0]

  accepter_peering_connection_id = concat(aws_vpc_peering_connection.cross_account_or_region[*].id,
                                          aws_vpc_peering_connection_accepter.cross_account_or_region[*].id)[0]

  requester_to_accepter = flatten([
    for id in var.requester_route_table_ids:
      [
        for associations in data.aws_vpc.accepter.cidr_block_associations:
          {
            route_table_id = id
            cidr_block     = associations.cidr_block
          }
      ]
  ])

  accepter_to_requester = flatten([
    for id in var.accepter_route_table_ids:
      [
        for associations in data.aws_vpc.requester.cidr_block_associations:
          {
            route_table_id = id
            cidr_block     = associations.cidr_block
          }
      ]
  ])
}

resource "aws_route" "requester_to_accepter" {
  count    = length(local.requester_to_accepter)
  provider = aws.requester

  route_table_id            = local.requester_to_accepter[count.index].route_table_id
  destination_cidr_block    = local.requester_to_accepter[count.index].cidr_block
  vpc_peering_connection_id = local.requester_peering_connection_id
}

resource "aws_route" "accepter_to_requester" {
  count    = length(local.accepter_to_requester)
  provider = aws.accepter

  route_table_id            = local.accepter_to_requester[count.index].route_table_id
  destination_cidr_block    = local.accepter_to_requester[count.index].cidr_block
  vpc_peering_connection_id = local.accepter_peering_connection_id
}
