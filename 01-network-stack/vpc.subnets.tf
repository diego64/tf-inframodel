resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_cidrs["public"]
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false # IP público só onde for explicitamente pedido

  tags = { Name = "${local.prefix}_SUBNET_PUBLIC", Tier = "public" }
}

resource "aws_subnet" "core" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnet_cidrs["core"]
  availability_zone = var.availability_zone

  tags = { Name = "${local.prefix}_SUBNET_CORE", Tier = "core" }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnet_cidrs["app"]
  availability_zone = var.availability_zone

  tags = { Name = "${local.prefix}_SUBNET_APP", Tier = "app" }
}
