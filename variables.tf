variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "ubuntu_ami_id" {
  type        = string
  description = "Canonical Ubuntu Server 24.04 LTS amd64 AMI in aws_region."
  validation {
    condition     = can(regex("^ami-[0-9a-f]+$", var.ubuntu_ami_id))
    error_message = "Provide a real AMI ID from the selected AWS region."
  }
}

variable "public_key_path" {
  type    = string
  default = "~/.ssh/devitaly_ec2.pub"
}

variable "ssh_allowed_cidr" {
  type        = string
  description = "Workstation public IPv4 with /32. Not the VM private address."
  validation {
    condition     = can(cidrnetmask(var.ssh_allowed_cidr)) && can(regex("/32$", var.ssh_allowed_cidr))
    error_message = "Use a valid IPv4 /32 for the workstation public address."
  }
}
