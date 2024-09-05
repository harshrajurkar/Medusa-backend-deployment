output "vpc_id" {
  value       = aws_vpc.medusa_vpc.id
  description = "The ID of the VPC"
}

# Add more outputs as needed