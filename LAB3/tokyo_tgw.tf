# -----------------------------
# Tokyo Transit Gateway
# -----------------------------
resource "aws_ec2_transit_gateway" "shinjuku_tgw01" {
  description = "shinjuku-tgw01"
  tags        = { Name = "shinjuku-tgw01" }
}

# -----------------------------
# Tokyo VPC attachment
# -----------------------------
resource "aws_ec2_transit_gateway_vpc_attachment" "shinjuku_attach_tokyo_vpc01" {
  transit_gateway_id = aws_ec2_transit_gateway.shinjuku_tgw01.id
  vpc_id             = aws_vpc.chewbacca_vpc01.id

  subnet_ids = [
    aws_subnet.chewbacca_private_subnet01.id,
    aws_subnet.chewbacca_private_subnet02.id
  ]

  tags = { Name = "shinjuku-attach-tokyo-vpc01" }
}

# -----------------------------
# Look up São Paulo TGW
# -----------------------------
data "aws_ec2_transit_gateway" "liberdade_tgw01" {
  provider = aws.saopaulo

  filter {
    name   = "tag:Name"
    values = ["liberdade-tgw01"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------
# TGW peering (Tokyo → São Paulo)
# -----------------------------
resource "aws_ec2_transit_gateway_peering_attachment" "shinjuku_to_liberdade_peer01" {
  transit_gateway_id      = aws_ec2_transit_gateway.shinjuku_tgw01.id
  peer_transit_gateway_id = data.aws_ec2_transit_gateway.liberdade_tgw01.id
  peer_region             = "sa-east-1"
  peer_account_id         = data.aws_ec2_transit_gateway.liberdade_tgw01.owner_id

  tags = { Name = "shinjuku-to-liberdade-peer01" }

  depends_on = [
    aws_ec2_transit_gateway_vpc_attachment.shinjuku_attach_tokyo_vpc01
  ]
}

# -----------------------------
# WAIT for peering to be usable
# -----------------------------
resource "time_sleep" "wait_for_tgw_peering_available" {
  depends_on = [
    aws_ec2_transit_gateway_peering_attachment_accepter.liberdade_accept_peer01
  ]

  create_duration = "90s"
}

# -----------------------------
# Tokyo TGW route → São Paulo
# -----------------------------
resource "aws_ec2_transit_gateway_route" "shinjuku_to_liberdade_tgw_static" {
  destination_cidr_block         = "10.102.0.0/16"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.shinjuku_to_liberdade_peer01.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.shinjuku_tgw01.propagation_default_route_table_id

  depends_on = [
    time_sleep.wait_for_tgw_peering_available
  ]
}
