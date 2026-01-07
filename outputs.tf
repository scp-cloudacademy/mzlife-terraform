# DevOps Infrastructure - Outputs

# VPC Outputs
output "vpc_id" {
  value = samsungcloudplatform_vpc.vpc.id
}

output "vpc_name" {
  value = samsungcloudplatform_vpc.vpc.name
}

# Internet Gateway Outputs
output "internet_gateway_id" {
  value = samsungcloudplatform_internet_gateway.igw.id
}

# Subnet Outputs
output "bastion_subnet_id" {
  value = samsungcloudplatform_subnet.bastion_subnet.id
}

output "k8s_subnet_id" {
  value = samsungcloudplatform_subnet.k8s_subnet.id
}

# NAT Gateway Outputs
output "nat_gateway_id" {
  value = samsungcloudplatform_nat_gateway.nat.id
}

output "nat_gateway_ip" {
  value = samsungcloudplatform_nat_gateway.nat.public_ipv4
}

# Load Balancer Outputs
output "load_balancer_id" {
  value = samsungcloudplatform_load_balancer.lb.id
}

output "load_balancer_name" {
  value = samsungcloudplatform_load_balancer.lb.name
}

# File Storage Outputs
output "file_storage_id" {
  value = samsungcloudplatform_file_storage.storage.id
}

output "file_storage_name" {
  value = samsungcloudplatform_file_storage.storage.file_storage_name
}

output "file_storage_name_uuid" {
  value = samsungcloudplatform_file_storage.storage.file_storage_name_uuid
}

# Security Group Outputs
output "bastion_security_group_id" {
  value = samsungcloudplatform_security_group.bastion_sg.id
}

output "k8s_security_group_id" {
  value = samsungcloudplatform_security_group.k8s_sg.id
}

# Bastion Host Outputs
output "bastion_server_id" {
  value = samsungcloudplatform_virtual_server.bastion_host.id
}

output "bastion_server_name" {
  value = samsungcloudplatform_virtual_server.bastion_host.virtual_server_name
}

output "bastion_internal_ip" {
  value = samsungcloudplatform_virtual_server.bastion_host.ipv4
}

output "bastion_nat_ip" {
  value = samsungcloudplatform_virtual_server.bastion_host.nat_ipv4
}

output "bastion_server_security_group_ids" {
  value       = samsungcloudplatform_virtual_server.bastion_host.security_group_ids
  description = "Security group IDs attached to bastion server"
}

# Kubernetes Cluster Outputs
output "k8s_cluster_id" {
  value = var.create_kubernetes_cluster ? samsungcloudplatform_kubernetes_engine.cluster[0].id : null
}

output "k8s_cluster_name" {
  value = var.create_kubernetes_cluster ? samsungcloudplatform_kubernetes_engine.cluster[0].name : null
}

output "k8s_version" {
  value = var.create_kubernetes_cluster ? samsungcloudplatform_kubernetes_engine.cluster[0].kubernetes_version : null
}

output "k8s_node_pool_ids" {
  value = var.create_kubernetes_cluster ? [for np in samsungcloudplatform_kubernetes_node_pool.node_pool : np.id] : []
}

output "k8s_node_pool_names" {
  value = var.create_kubernetes_cluster ? [for np in samsungcloudplatform_kubernetes_node_pool.node_pool : np.name] : []
}
