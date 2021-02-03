provider "aws" {
  region = var.aws_region
}

resource "tls_private_key" "gp_dev" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "gp_dev" {
  key_name   = var.dwcluster_name
  public_key = tls_private_key.gp_dev.public_key_openssh
}

resource "aws_vpc" "gp_dev" {
  enable_dns_support = true
  enable_dns_hostnames = true

  cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.dwcluster_name
  }
}

resource "aws_subnet" "gp_dev" {
  vpc_id = aws_vpc.gp_dev.id

  cidr_block = cidrsubnet(aws_vpc.gp_dev.cidr_block, 4, 1)
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.gp_dev.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true

  tags = {
    Name = var.dwcluster_name
  }
}

resource "aws_internet_gateway" "gp_dev" {
  vpc_id = aws_vpc.gp_dev.id
  tags = {
    Name = var.dwcluster_name
  }
}

resource "aws_default_route_table" "gp_dev" {
  default_route_table_id = aws_vpc.gp_dev.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gp_dev.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gp_dev.id
  }
  tags = {
    Name = var.dwcluster_name
  }
}

resource "aws_route_table_association" "gp_dev" {
  subnet_id      = aws_subnet.gp_dev.id
  route_table_id = aws_default_route_table.gp_dev.id
}

resource "aws_security_group" "gp_dev" {
  name = var.dwcluster_name
  vpc_id = aws_vpc.gp_dev.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "${var.dwcluster_name}_jumpbox"
  }
}

resource "aws_instance" "gp_dev_jumpbox" {

  ami = var.ami
  instance_type = "t2.large"

  key_name = aws_key_pair.gp_dev.key_name

  subnet_id = aws_subnet.gp_dev.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_dev.id]

  depends_on = [aws_internet_gateway.gp_dev]

  tags = {
    Name = "${var.dwcluster_name}_jumpbox"
  }
}

resource "aws_instance" "gp_dev_dwcoordinator" {

  count = var.dwcoordinator_instance_count

  ami = var.ami
  instance_type = var.dwcoordinator_instance_type

  key_name = aws_key_pair.gp_dev.key_name

  subnet_id = aws_subnet.gp_dev.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_dev.id]

  depends_on = [aws_internet_gateway.gp_dev]

  tags = {
    Name = "var.dwcluster_name + _mdw"
  }

  root_block_device {
    volume_size = "200"
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.dwcoordinator_ebs_volume_size
    volume_type = var.dwdatanode_ebs_volume_type
  }
}

resource "aws_instance" "gp_dev_dwdatanode" {

  count = var.dwdatanode_instance_count

  ami = var.ami
  instance_type = var.dwdatanode_instance_type

  key_name = aws_key_pair.gp_dev.key_name

  subnet_id = aws_subnet.gp_dev.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_dev.id]

  depends_on = [aws_internet_gateway.gp_dev]

  tags = {
    Name = format("${var.dwcluster_name}_sdw%d", count.index + 1)
  }

  root_block_device {
    volume_size = "200"
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.dwdatanode_ebs_volume_size
    volume_type = var.dwdatanode_ebs_volume_type
  }

  ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = var.dwdatanode_ebs_volume_size
    volume_type = var.dwdatanode_ebs_volume_type
  }

  ebs_block_device {
    device_name = "/dev/sdh"
    volume_size = var.dwdatanode_ebs_volume_size
    volume_type = var.dwdatanode_ebs_volume_type
  }
}

output "gp_dev_jumpbox-public-IPv4" {
  value = aws_instance.gp_dev_jumpbox.public_ip
}

output "gp_dev_dwcoordinators-public-IPv4" {
  value = aws_instance.gp_dev_dwcoordinator[*].public_ip
}

output "gp_dev_dwcoordinators-private-IPv4" {
  value = aws_instance.gp_dev_dwcoordinator[*].private_ip
}

output "gp_dev_dwdatanodes-public-IPv4" {
  value = aws_instance.gp_dev_dwdatanode[*].public_ip
}

output "gp_dev_dwdatanodes-private-IPv4" {
  value = aws_instance.gp_dev_dwdatanode[*].private_ip
}

output "gp_dev_dwcoordinators-private-IPv6" {
  value = aws_instance.gp_dev_dwcoordinator[*].ipv6_addresses[0]
}

output "gp_dev_dwdatanodes-private-IPv6" {
  value = aws_instance.gp_dev_dwdatanode[*].ipv6_addresses[0]
}
