resource "aws_iam_instance_profile" "ec2" {
  name = "${local.prefix}_PROFILE_EC2_SSM"
  role = aws_iam_role.ec2.name

  tags = { Name = "${local.prefix}_PROFILE_EC2_SSM" }
}
