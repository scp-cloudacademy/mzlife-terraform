# DevOps Infrastructure - Variables

# User Input Variables
variable "user_public_ip" {
  type        = string
  description = "User public IP address"
  default     = "your_public_ip"
}

# Common Variables
variable "region" {
  type        = string
  description = "Region for the infrastructure"
  default     = "KR-WEST-1"
}

variable "service_zone_west1" {
  type        = string
  description = "Region for the infrastructure"
  default     = "ZONE-FClPklmysrhRpknZ6DaI2f"
}

variable "service_zone_west2" {
  type        = string
  description = "Region for the infrastructure"
  default     = "ZONE-lxu6F_ntqxeIMaZZwh2I-p"
}

variable "service_zone_west" {
  type        = string
  description = "Region for the infrastructure"
  default     = "ZONE-1txHHEZvs5cPYfYpy2_FPc"
}

variable "service_zone_east1" {
  type        = string
  description = "Region for the infrastructure"
  default     = "ZONE-Yi4UK3uHsujPbQYqsRgo7i"
}

variable "prefix" {
  type    = string
  default = "mzlife"
}

# 2. Internet Gateway
variable "igw_type" {
  type    = string
  default = "SHARED"
}

# 3. Public Subnet for Bastion VM 
variable "bastion_subnet_name" {
  type    = string
  default = "SBNbastion"
}

variable "bastion_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

# 4. Private Subnet for Kubernetes Cluster
variable "k8s_subnet_name" {
  type    = string
  default = "SBNk8s"
}

variable "k8s_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

# 6. Load Balancer
variable "load_balancer_size" {
  type    = string
  default = "SMALL"
}

variable "lb_cidr_ipv4" {
  type    = string
  default = "10.0.0.0/27"
}

# Bastion Security Group
variable "bastion_sg_name" {
  type    = string
  default = "SGbastion"
}

variable "bastion_sg_loggable" {
  type    = bool
  default = false
}

# Kubernetes Security Group
variable "k8s_sg_name" {
  type    = string
  default = "SGk8s"
}

variable "k8s_sg_loggable" {
  type    = bool
  default = false
}

# Bastion Host
variable "bastion_server_name" {
  type    = string
  default = "vmbastion"
}

variable "bastion_key_pair_name" {
  type        = string
  description = "Key Pair name for bastion host SSH access"
  default     = "mykey"
}

variable "bastion_os_storage_name" {
  type    = string
  default = "blockbastion"
}

variable "bastion_os_storage_size_gb" {
  type    = number
  default = 100
}

# Kubernetes Cluster
variable "k8s_version" {
  type    = string
  default = "v1.31.8"
}

# Kubernetes Node Pool
variable "k8s_node_pools" {
  type = list(object({
    node_pool_name         = string
    image_id               = string
    scale_name             = string
    storage_name           = string
    storage_size_gb        = string
    encrypt_enabled        = bool
    desired_node_count     = number
    auto_scale             = bool
    min_node_count         = number
    max_node_count         = number
    auto_recovery          = bool
    availability_zone_name = string
  }))
  default = [
    {
      node_pool_name         = "node"
      image_id               = "IMAGE-P2TZSc96tEjQpFaufbNrWb"
      scale_name             = "s1v2m8"
      storage_name           = "SSD"
      storage_size_gb        = "100"
      encrypt_enabled        = false
      desired_node_count     = 2
      auto_scale             = false
      min_node_count         = 2
      max_node_count         = 5
      auto_recovery          = false
      availability_zone_name = ""
    }
  ]
}

# File Storage
variable "file_storage_name" {
  type    = string
  default = "k8spvc"
}

variable "file_storage_disk_type" {
  type    = string
  default = "HDD"
}

variable "file_storage_protocol" {
  type    = string
  default = "NFS"
}

variable "file_storage_product_names" {
  type    = list(string)
  default = ["HDD"]
}

variable "create_kubernetes_cluster" {
  type    = bool
  default = true
}
