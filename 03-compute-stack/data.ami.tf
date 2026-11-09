# Ubuntu Server 22.04 LTS (Jammy) oficial — owner 099720109477 = Canonical.
# "hvm-ssd*" cobre os prefixos hvm-ssd e hvm-ssd-gp3.
# Ref.: https://documentation.ubuntu.com/aws/en/latest/aws-how-to/instances/find-ubuntu-images/
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
