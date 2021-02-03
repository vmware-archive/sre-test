variable "aws_region" {
  default = "us-west-1"
}

variable "aws_zone" {
  default = "us-west-1a"
}

variable "dwcluster_name" {
  default = "gp_dev"
}

variable "dwcoordinator_instance_count" {
  default = 2
}

variable "dwdatanode_instance_count" {
  default = 2
}

variable "dwcoordinator_ebs_volume_size" {
  default = 500
}

variable "dwdatanode_ebs_volume_size" {
  default = 2048
}

variable "dwdatanode_ebs_volume_type" {
  default = "sc1"
}

variable "dwcoordinator_instance_type" {
  default = "r5.xlarge"
}

variable "dwdatanode_instance_type" {
  default = "r5.4xlarge"
}

variable "ami" {
  default = "ami-098f55b4287a885ba" # CentOS 7 (x86_64) - with Updates HVM
}
