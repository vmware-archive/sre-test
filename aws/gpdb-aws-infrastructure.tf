#terraform script to setup Greenplum Cluster

#provider details
provider "aws" {
  region = var.aws_region
}

#create private key
resource "tls_private_key" "gp_prod_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#create aws key-pair
resource "aws_key_pair" "gp_prod_key_pair" {
  key_name   = var.dwcluster_name
  public_key = tls_private_key.gp_prod_private_key.public_key_openssh
}

#create VPC network
resource "aws_vpc" "gp_prod_vpc" {
  enable_dns_support = true
  enable_dns_hostnames = true

  cidr_block = "10.0.0.0/16"

  assign_generated_ipv6_cidr_block = true

  tags = {
    Name = var.dwcluster_name
  }
}
#create subnet
resource "aws_subnet" "gp_prod_subnet" {
  vpc_id = aws_vpc.gp_prod_vpc.id
  availability_zone = var.aws_zone
  cidr_block = cidrsubnet(aws_vpc.gp_prod_vpc.cidr_block, 4, 1)
  map_public_ip_on_launch = true

  ipv6_cidr_block = cidrsubnet(aws_vpc.gp_prod_vpc.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation = true

  tags = {
    Name = var.dwcluster_name
  }
}

#create VPC Internet Gateway
resource "aws_internet_gateway" "gp_prod_gateway" {
  vpc_id = aws_vpc.gp_prod_vpc.id
  tags = {
    Name = var.dwcluster_name
  }
}

#create default VPC routing table
resource "aws_default_route_table" "gp_prod_route_table" {
  default_route_table_id = aws_vpc.gp_prod_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gp_prod_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id = aws_internet_gateway.gp_prod_gateway.id
  }
  tags = {
    Name = var.dwcluster_name
  }
}

#create an association between a route table and a subnet 
resource "aws_route_table_association" "gp_prod_rt_association" {
  subnet_id      = aws_subnet.gp_prod_subnet.id
  route_table_id = aws_default_route_table.gp_prod_route_table.id
}

#create security group
resource "aws_security_group" "gp_prod_sec_group" {
  name = var.dwcluster_name
  vpc_id = aws_vpc.gp_prod_vpc.id
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
    Name = "${var.dwcluster_name}"
  }
}

#create master instance
resource "aws_instance" "gp_prod_dwcoordinator" {
  ami = var.ami
  instance_type = var.dwcoordinator_instance_type

  key_name = aws_key_pair.gp_prod_key_pair.key_name

  subnet_id = aws_subnet.gp_prod_subnet.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_prod_sec_group.id]

  depends_on = [aws_internet_gateway.gp_prod_gateway]

  tags = {
    Name = "${var.dwcluster_name}_mdw",
	Description = "${var.dwcluster_name}"
  }

  root_block_device {
    volume_size = "200"
    volume_type = "gp2"
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_size = var.dwcoordinator_ebs_volume_size
    volume_type = var.dwcoordinator_ebs_volume_type
  }
}

#create standby master instance
resource "aws_instance" "gp_prod_dwstandbycoordinator" {
  ami = var.ami
  instance_type = var.dwcoordinator_instance_type

  key_name = aws_key_pair.gp_prod_key_pair.key_name

  subnet_id = aws_subnet.gp_prod_subnet.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_prod_sec_group.id]

  depends_on = [aws_internet_gateway.gp_prod_gateway]

  tags = {
    Name = "${var.dwcluster_name}_smdw",
	Description = "${var.dwcluster_name}"
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

#create segments hosts instances
resource "aws_instance" "gp_prod_dwdatanode" {

  count = var.dwdatanode_instance_count

  ami = var.ami
  instance_type = var.dwdatanode_instance_type

  key_name = aws_key_pair.gp_prod_key_pair.key_name

  subnet_id = aws_subnet.gp_prod_subnet.id

  ipv6_address_count = 1

  vpc_security_group_ids = [aws_security_group.gp_prod_sec_group.id]

  depends_on = [aws_internet_gateway.gp_prod_gateway]

  tags = {
    Name = format("${var.dwcluster_name}_sdw%d", count.index + 1),
	Description = "${var.dwcluster_name}"
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

#Outputs

output "gp_prod_dwcoordinators-public-IPv4" {
  value = aws_instance.gp_prod_dwcoordinator.public_ip
}
output "gp_prod_dwstandbycoordinators-public-IPv4" {
  value = aws_instance.gp_prod_dwstandbycoordinator.public_ip
}

output "gp_prod_dwcoordinators-private-IPv4" {
  value = aws_instance.gp_prod_dwcoordinator.private_ip
}

output "gp_prod_dwstandbycoordinators-private-IPv4" {
  value = aws_instance.gp_prod_dwstandbycoordinator.private_ip
}

output "gp_prod_dwcoordinators-private-IPv6" {
  value = aws_instance.gp_prod_dwcoordinator.ipv6_addresses[0]
}

output "gp_prod_dwstandbycoordinators-private-IPv6" {
  value = aws_instance.gp_prod_dwstandbycoordinator.ipv6_addresses[0]
}

output "gp_prod_dwdatanodes-public-IPv4" {
  value = aws_instance.gp_prod_dwdatanode[*].public_ip
}

output "gp_prod_dwdatanodes-private-IPv4" {
  value = aws_instance.gp_prod_dwdatanode[*].private_ip
}

output "gp_prod_dwdatanodes-private-IPv6" {
  value = aws_instance.gp_prod_dwdatanode[*].ipv6_addresses[0]
}

