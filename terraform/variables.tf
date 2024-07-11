variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets"
  type        = list(string)
}
