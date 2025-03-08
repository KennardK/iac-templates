data "aws_iam_policy_document" "assumerole_ec2" {

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

  }
}
resource "aws_iam_role" "ssm" {
  name               = "ec2-instance-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assumerole_ec2.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.ssm.name
  # policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ssm" {
  name = aws_iam_role.ssm.name
  role = aws_iam_role.ssm.name
}

data "aws_ami" "amazonlinux_2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }
}

resource "aws_instance" "main" {
  ami                         = data.aws_ami.amazonlinux_2023.id
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_role.ssm.name
  subnet_id                   = aws_subnet.private_subnet.id
  vpc_security_group_ids      = [aws_default_security_group.default.id]
  associate_public_ip_address = false
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }
  tags = {
    Name = "${var.prefix}-ec2-for-testing"
  }
}