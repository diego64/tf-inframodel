# FAF_ROLE_EC2_SSM — Session Manager + leitura dos segredos de bootstrap
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.prefix}_ROLE_EC2_SSM"
  description        = "Role das instancias ${local.prefix}: SSM Session Manager + leitura de segredos"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = { Name = "${local.prefix}_ROLE_EC2_SSM" }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "read_secrets" {
  statement {
    sid     = "ReadBootstrapSecrets"
    actions = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_prefix}/*"
    ]
  }

  # Chave gerenciada aws/ssm: decrypt apenas quando chamado via SSM
  statement {
    sid       = "DecryptViaSSM"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "read_secrets" {
  name   = "${local.prefix}_POLICY_READ_SECRETS"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.read_secrets.json
}
