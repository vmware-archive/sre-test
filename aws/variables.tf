variable "aws_region" {
  description  = "AWS region to be chosen for provisioning"
  type = string
  default = "ap-south-1"
}

variable "aws_zone" {
  description  = "AWS AZ to be chosen for provisioning"
  type = string
  default = "ap-south-1a"
}

variable "dwcluster_name" {
  description  = "Greenplum DW Cluster Name"
  type = string
  default = "gp_prod2"
}

variable "dwdatanode_instance_count" {
  description  = "Number of segment hosts"
  type = number
  default = 2
}

variable "dwcoordinator_instance_type" {
  description  = "Master node instance type"
  type = string
  default = "r5.4xlarge"
}


variable "dwcoordinator_ebs_volume_size" {
  description  = "Master node volume size"
  type = number
  default = 512
}


variable "dwcoordinator_ebs_volume_type" {
  description  = "segment host node volume type"
  type = string
  default = "sc1"
}

variable "dwdatanode_ebs_volume_size" {
  description  = "segment host node volume size"
  type = number
  default = 512
}

variable "dwdatanode_ebs_volume_type" {
  description  = "segment host node volume type"
  type = string
  default = "sc1"
}

variable "dwdatanode_instance_type" {
  description  = "segment host node instance type"
  type = string
  default = "r5.4xlarge"
}

variable "ami" {
  description  = "AWS AMI to be used for provisioning instances"
  type = string
  default = "ami-026f33d38b6410e30" # ap-south-1 - CentOS 7 (x86_64) - with Updates HVM
}


