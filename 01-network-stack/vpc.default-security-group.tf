# Assume o SG default da VPC e remove todas as regras (CIS AWS 5.4)
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${local.prefix}_SG_DEFAULT_LOCKED" }
}
