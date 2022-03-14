
moved {
  from = module.teleport_cluster.aws_subnet.public[1]
  to = module.teleport_cluster.aws_subnet.public["us-west-2b"]
}
