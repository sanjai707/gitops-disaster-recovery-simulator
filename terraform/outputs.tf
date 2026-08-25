output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}
output "ec2_instance_id" {
  description = "ID of the k3s EC2 instance"
  value       = aws_instance.k3s_server.id
}
output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k3s_server.public_ip
}
output "ssh_command" {
  description = "Command used to SSH into the EC2 instance"
  value       = "ssh -i <path-to-private-key.pem> ubuntu@${aws_instance.k3s_server.public_ip}"
}