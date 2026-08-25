aws_region   = "ap-south-1"
project_name = "gitops-dr-simulator"

vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"

instance_type = "t3.micro"

key_name = "gitops-dr-key"

ssh_allowed_cidr = "103.211.17.177/32"