provider "aws" {
  region = "${var.aws_region}"
  shared_credentials_file = "~/.aws/credentials"
  profile = "default"
}

resource "aws_vpc" "terra_vpc" {
  cidr_block       = "${var.vpc_cidr}"
  instance_tenancy = "default"

  tags = {
    Name = "Terraform_AG"
  }
}

resource "aws_subnet" "terra_ingress_subnet_az_1" {
  vpc_id     = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${var.ingress_subnet_az_1_CIDR}"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "SBN01-AG-Pub"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_subnet" "terra_ingress_subnet_az_2" {
  vpc_id     = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${var.ingress_subnet_az_2_CIDR}"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "SBN02-AG-Pub"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_subnet" "terra_private_subnet_az_1" {
  vpc_id     = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${var.private_subnet_az_1_CIDR}"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "SBN03-AG-Private"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_subnet" "terra_private_subnet_az_2" {
  vpc_id     = "${aws_vpc.terra_vpc.id}"
  cidr_block        = "${var.private_subnet_az_2_CIDR}"
  availability_zone = "eu-west-1b"

  tags = {
    Name = "SBN04-AG-Private"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_security_group" "ALB_AG" {
  name        = "ALB_AG"
  description = "Allow all inbound traffic"
  vpc_id     = "${aws_vpc.terra_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
	from_port  = 8080
	to_port = 8080
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.private_subnet_az_1_CIDR}"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.private_subnet_az_2_CIDR}"]
  }

  tags = {
    Name = "ALB_AG"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_security_group" "terra_Application_server_sg" {
  name        = "terra_application_server_sg"
  description = "Allow all inbound traffic"
  vpc_id     = "${aws_vpc.terra_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_subnet_az_1_CIDR}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_subnet_az_2_CIDR}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ingress_subnet_az_1_CIDR}"]
  }

  tags = {
    Name = "terra_Application_server_sg"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_security_group" "terra_bastion_sg" {
  name        = "terra_bastion_sg"
  description = "Allow all inbound traffic"
  vpc_id     = "${aws_vpc.terra_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_sshrdp_from}"]
  }
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${var.bastion_sshrdp_from}"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.private_subnet_az_1_CIDR}"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.private_subnet_az_2_CIDR}"]
  }

  tags = {
    Name = "terra_bastion_sg"
  }

  depends_on = [
    "aws_vpc.terra_vpc"
  ]
}

resource "aws_launch_configuration" "terra_bastion_lc" {
  name_prefix   = "terraform-bastion-"
  image_id      = "ami-031a3db8bacbcdc20"
  instance_type = "t2.small"
  key_name      = "AG_TestingKey"
  security_groups = ["${aws_security_group.terra_bastion_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    "aws_security_group.terra_bastion_sg"
  ]
}

resource "aws_autoscaling_group" "terra-bastion" {
  name                 = "terraform-bastion-asg"
  launch_configuration = "${aws_launch_configuration.terra_bastion_lc.name}"
  min_size             = 1
  max_size             = 1
  vpc_zone_identifier       = ["${aws_subnet.terra_ingress_subnet_az_1.id}"]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    "aws_launch_configuration.terra_bastion_lc",
    "aws_subnet.terra_ingress_subnet_az_1",
  ]
}