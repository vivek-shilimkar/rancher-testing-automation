variable "name" {
  default = "vivek-rancher-Server"
}

variable "ami" {
  type    = string
  default = "ami-0629230e074c580f2"
}

variable "instance_type" {
  type    = string
  default = "t3a.xlarge"
}

variable "aws_region" {
  default = "us-east-2a"
}

variable "subnet_id_for_ec2" {
  description = "EC2 instance to be deployed in the subnet"
  default     = "subnet-6127e62d"
}

variable "vpc_security_group_id_for_ec2" {
  description = "Security group to be attached to the EC2 instance"
  default     = "sg-c42018a9"
}

variable "rancher_version" {
  description = "Rancher version to be installed"
}

variable "AWS_KEY_ID" {
  description = "AWS KEY ID"
}

variable "AWS_SECRET_KEY_ID" {
  description = "SECRET KEY ID"
}

variable "AWS_REGION" {
  description = "AWS REGION"
}

variable "AWS_DEFAULT_OUTPUT" {
  description = "AWS DEFAULT OUTPUT"
}
