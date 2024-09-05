# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_1_cidr" {
  description = "The CIDR block for the first subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_2_cidr" {
  description = "The CIDR block for the second subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_url" {
  description = "The URL for the PostgreSQL database"
  type        = string
  # This should be set via environment variable or Terraform Cloud variable
  # Do not hardcode sensitive information here
}

variable "redis_url" {
  description = "The URL for the Redis instance"
  type        = string
  # This should be set via environment variable or Terraform Cloud variable
  # Do not hardcode sensitive information here
}

variable "medusa_image_tag" {
  description = "The tag for the Medusa Docker image"
  type        = string
  default     = "latest"
}

variable "ecs_task_cpu" {
  description = "The amount of CPU to allocate for the ECS task"
  type        = string
  default     = "256"
}

variable "ecs_task_memory" {
  description = "The amount of memory to allocate for the ECS task"
  type        = string
  default     = "512"
}

variable "ecs_task_desired_count" {
  description = "The desired number of instances of the ECS task to run"
  type        = number
  default     = 1
}

variable "medusa_container_port" {
  description = "The port on which the Medusa container listens"
  type        = number
  default     = 9000
}

variable "health_check_path" {
  description = "The path for the ALB health check"
  type        = string
  default     = "/health"
}

variable "logs_retention_days" {
  description = "The number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}