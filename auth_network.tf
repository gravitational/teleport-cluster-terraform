// Auth subnets are for authentication servers
resource "aws_route_table" "auth" {
  for_each = var.az_list

  vpc_id = local.vpc_id
  tags   = {
    Name            = "teleport-auth-${each.key}"
    TeleportCluster = var.cluster_name
  }
}

// Route all outbound traffic through NAT gateway
// Auth servers do not have public IP address and are located
// in their own subnet restricted by security group rules.
resource "aws_route" "auth" {
  for_each = aws_route_table.auth

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.teleport[each.key].id
  depends_on             = [aws_route_table.auth]
}

# A subnet for each availability zone in the region.
resource "aws_subnet" "auth" {
  for_each = var.az_list

  vpc_id            = local.vpc_id
  cidr_block        = cidrsubnet(local.auth_cidr, 4, var.az_number[substr(each.key, 9, 1)])
  availability_zone = each.key
  tags              = {
    Name            = "teleport-auth-${each.key}"
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

resource "aws_route_table_association" "auth" {
  for_each = aws_subnet.auth

  subnet_id      = each.value.id
  route_table_id = aws_route_table.auth[each.key].id
}

// Security groups for auth servers only allow access to 3025 port from
// public subnets, and not the internet
resource "aws_security_group" "auth" {
  name        = "${substr(var.cluster_name, 0, 16)}-auth"
  description = "Security group for ${substr(var.cluster_name, 0, 16)}-auth"
  vpc_id      = local.vpc_id
  tags        = {
    TeleportCluster = var.cluster_name
  }
}

// SSH emergency access via bastion security groups
resource "aws_security_group_rule" "auth_ingress_allow_ssh" {
  description              = "SSH emergency access via bastion security groups"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.auth.id
  source_security_group_id = aws_security_group.bastion.id
}

// Internal traffic within the security group is allowed.
resource "aws_security_group_rule" "auth_ingress_allow_internal_traffic" {
  description       = "Internal traffic within the security group is allowed"
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.auth.id
}

// Allow traffic from public subnet to auth servers - this is to
// let proxies to talk to auth server API.
// This rule uses CIDR as opposed to security group ip because traffic coming from NLB
// (network load balancer from Amazon)
// is not marked with security group ID and rules using the security group ids do not work,
// so CIDR ranges are necessary.
resource "aws_security_group_rule" "auth_ingress_allow_cidr_traffic" {
  description       = "Allow traffic from public subnet to auth servers in order to allow proxies to talk to auth server API"
  type              = "ingress"
  from_port         = 3025
  to_port           = 3025
  protocol          = "tcp"
  cidr_blocks       = [for subnet in aws_subnet.public : subnet.cidr_block]
  security_group_id = aws_security_group.auth.id
}

// Allow traffic from nodes to auth servers.
// Teleport nodes heartbeat presence to auth server.
// This rule uses CIDR as opposed to security group ip becasue traffic coming from NLB
// (network load balancer from Amazon)
// is not marked with security group ID and rules using the security group ids do not work,
// so CIDR ranges are necessary.
resource "aws_security_group_rule" "auth_ingress_allow_node_cidr_traffic" {
  description       = "Allow traffic from nodes to auth servers in order to allow Teleport nodes heartbeat presence to auth server"
  type              = "ingress"
  from_port         = 3025
  to_port           = 3025
  protocol          = "tcp"
  cidr_blocks       = [for subnet in aws_subnet.node : subnet.cidr_block]
  security_group_id = aws_security_group.auth.id
}

// This rule allows non NLB traffic originating directly from proxies
resource "aws_security_group_rule" "auth_ingress_allow_public_traffic" {
  description              = "Allow non-NLB traffic originating directly from proxies"
  type                     = "ingress"
  from_port                = 3025
  to_port                  = 3025
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.proxy.id
  security_group_id        = aws_security_group.auth.id
}

// All egress traffic is allowed
// tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "auth_egress_allow_all_traffic" {
  description       = "Permit all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.auth.id
}

// Network load balancer for auth server.
resource "aws_lb" "auth" {
  name               = "${substr(var.cluster_name, 0, 16)}-auth"
  internal           = true
  subnets            = [for subnet in aws_subnet.public : subnet.id]
  load_balancer_type = "network"
  idle_timeout       = 3600

  tags = {
    TeleportCluster = var.cluster_name
  }
}

// Target group is associated with auto scale group
resource "aws_lb_target_group" "auth" {
  name     = "${substr(var.cluster_name, 0, 16)}-auth"
  port     = 3025
  vpc_id   = aws_vpc.teleport.id
  protocol = "TCP"
}

// 3025 is the Auth servers API server listener.
resource "aws_lb_listener" "auth" {
  load_balancer_arn = aws_lb.auth.arn
  port              = "3025"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.auth.arn
    type             = "forward"
  }
}
