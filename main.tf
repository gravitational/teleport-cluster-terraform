
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
