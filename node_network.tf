// Node subnets are for teleport nodes joining the cluster
// Nodes are not accessible via internet and are accessed
// via emergency access bastions or proxies
resource "aws_route_table" "node" {
  for_each = var.az_list

  vpc_id = local.vpc_id
  tags   = {
    Name            = "teleport-node-${each.key}"
    TeleportCluster = var.cluster_name
  }
}

// Route all outbound traffic through NAT gateway
resource "aws_route" "node" {
  for_each = aws_route_table.node

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.teleport[each.key].id
  depends_on             = [aws_route_table.node]
}

resource "aws_subnet" "node" {
  for_each = var.az_list

  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(local.node_cidr, 4, var.az_number[substr(each.key, 9, 1)])
  availability_zone = each.key
  tags              = {
    Name            = "teleport-node-${each.key}"
    TeleportCluster = var.cluster_name
  }
  tags_all = {
    "Name"            = "teleport-auth-us-west-2a"
    "TeleportCluster" = "infra-dev"
  }
  ipv6_native                                    = false
  map_customer_owned_ip_on_launch                = false
  enable_resource_name_dns_aaaa_record_on_launch = false
  enable_resource_name_dns_a_record_on_launch    = false
  enable_dns64                                   = false
  private_dns_hostname_type_on_launch            = "ip-name"
}

resource "aws_route_table_association" "node" {
  for_each = aws_subnet.node

  subnet_id      = each.value.id
  route_table_id = aws_route_table.node[each.key].id
}

// Node security groups do not allow direct internet access
// and only allow traffic comming in from proxies or
// emergency access bastions
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node"
  description = "SG for ${var.cluster_name}-node"
  vpc_id      = local.vpc_id
  tags        = {
    TeleportCluster = var.cluster_name
  }
}

// SSH access is allowed via bastions and proxies
resource "aws_security_group_rule" "node_ingress_allow_ssh_bastion" {
  description              = "Allow SSH access via bastion"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.bastion.id
}

resource "aws_security_group_rule" "node_ingress_allow_ssh_proxy" {
  description              = "Allow SSH access via proxy"
  type                     = "ingress"
  from_port                = 3022
  to_port                  = 3022
  protocol                 = "tcp"
  security_group_id        = aws_security_group.node.id
  source_security_group_id = aws_security_group.proxy.id
}

// tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "node_egress_allow_all_traffic" {
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.node.id
}
