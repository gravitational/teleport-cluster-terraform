
moved {
  from = aws_subnet.public[0]
  to = aws_subnet.public["us-west-2a"]
}

moved {
  from = aws_subnet.public[1]
  to = aws_subnet.public["us-west-2b"]
}

moved {
  from = aws_subnet.auth[0]
  to = aws_subnet.auth["us-west-2a"]
}

moved {
  from = aws_subnet.auth[1]
  to = aws_subnet.auth["us-west-2b"]
}

moved {
  from = aws_route_table_association.public[0]
  to = aws_route_table_association.public["us-west-2a"]
}

moved {
  from = aws_route_table_association.public[1]
  to = aws_route_table_association.public["us-west-2b"]
}

moved {
  from = aws_route_table_association.auth[0]
  to = aws_route_table_association.auth["us-west-2a"]
}

moved {
  from = aws_route_table_association.auth[1]
  to = aws_route_table_association.auth["us-west-2b"]
}

moved {
  from = aws_route_table.public[0]
  to = aws_route_table.public["us-west-2a"]
}

moved {
  from = aws_route_table.public[1]
  to = aws_route_table.public["us-west-2b"]
}

moved {
  from = aws_route_table.auth[0]
  to = aws_route_table.auth["us-west-2a"]
}

moved {
  from = aws_route_table.auth[1]
  to = aws_route_table.auth["us-west-2b"]
}

moved {
  from = aws_route.public_gateway[0]
  to = aws_route.public_gateway["us-west-2a"]
}

moved {
  from = aws_route.public_gateway[1]
  to = aws_route.public_gateway["us-west-2b"]
}

moved {
  from = aws_route.auth[0]
  to = aws_route.auth["us-west-2a"]
}

moved {
  from = aws_route.auth[1]
  to = aws_route.auth["us-west-2b"]
}

moved {
  from = aws_nat_gateway.teleport[0]
  to = aws_nat_gateway.teleport["us-west-2a"]
}

moved {
  from = aws_nat_gateway.teleport[1]
  to = aws_nat_gateway.teleport["us-west-2b"]
}

moved {
  from = aws_eip.nat[0]
  to = aws_eip.nat["us-west-2a"]
}

moved {
  from = aws_eip.nat[1]
  to = aws_eip.nat["us-west-2b"]
}
