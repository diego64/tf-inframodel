# ---------- Pública: saída pelo IGW ----------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${local.prefix}_RT_PUBLIC" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ---------- Privada (core + app) ----------
# A rota 0.0.0.0/0 -> FAF_GATEWAY é criada na 03-compute-stack (ec2.gateway.tf),
# pois depende da ENI da instância.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${local.prefix}_RT_PRIVATE" }
}

resource "aws_route_table_association" "core" {
  subnet_id      = aws_subnet.core.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app" {
  subnet_id      = aws_subnet.app.id
  route_table_id = aws_route_table.private.id
}
