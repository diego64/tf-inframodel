variable "instances" {
  description = "Mapa chave-estável -> definição da instância."
  type = map(object({
    service           = string
    index             = number
    name              = string
    hostname          = string
    instance_type     = string
    tier              = string
    private_ip        = string
    volume_size       = number
    public            = bool
    source_dest_check = bool
    user_data         = string
  }))
}

variable "ami_id" {
  description = "AMI (Ubuntu 22.04 LTS)."
  type        = string
}

variable "subnet_id_by_tier" {
  description = "Mapa tier (public/core/app) -> subnet ID."
  type        = map(string)
}

variable "security_group_by_service" {
  description = "Mapa serviço -> security group ID."
  type        = map(string)
}

variable "instance_profile_name" {
  description = "Instance profile IAM."
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "CloudWatch detailed monitoring."
  type        = bool
  default     = false
}
