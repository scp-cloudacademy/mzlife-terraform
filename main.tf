# DevOps Infrastructure - Main Configuration

terraform {
  required_providers {
    samsungcloudplatform = {
      version = "3.16.0"
      source  = "SamsungSDSCloud/samsungcloudplatform"
    }
  }
  required_version = ">= 0.13"
}

provider "samsungcloudplatform" {
}

# ============================================
# Data Sources
# ============================================
data "samsungcloudplatform_region" "region" {
}

data "samsungcloudplatform_standard_image" "bastion_image" {
  service_group = "COMPUTE"
  service       = "Virtual Server"
  region        = data.samsungcloudplatform_region.region.location

  filter {
    name      = "image_name"
    values    = ["Rocky 9.6 *"]
    use_regex = true
  }
}

# ============================================
# Resources
# ============================================

# 1. VPC
resource "samsungcloudplatform_vpc" "mz_vpc" {
  name        = "${var.prefix}VPC"
  region      = var.region
}

# 2. Internet Gateway
resource "samsungcloudplatform_internet_gateway" "igw" {
  vpc_id     = samsungcloudplatform_vpc.mz_vpc.id
  igw_type   = var.igw_type
  depends_on = [samsungcloudplatform_vpc.mz_vpc]
}

# 3. Public Subnet for Bastion VM 
resource "samsungcloudplatform_subnet" "bastion_subnet" {
  vpc_id     = samsungcloudplatform_vpc.mz_vpc.id
  name       = var.bastion_subnet_name
  type       = "PUBLIC"
  cidr_ipv4  = var.bastion_subnet_cidr
  depends_on = [
    samsungcloudplatform_vpc.mz_vpc, 
    samsungcloudplatform_internet_gateway.igw
  ]
}

# 4. Private Subnet for Kubernetes Cluster
resource "samsungcloudplatform_subnet" "k8s_subnet" {
  vpc_id     = samsungcloudplatform_vpc.mz_vpc.id
  name       = var.k8s_subnet_name
  type       = "PRIVATE"
  cidr_ipv4  = var.k8s_subnet_cidr
  depends_on = [
    samsungcloudplatform_vpc.mz_vpc, 
    samsungcloudplatform_internet_gateway.igw
  ]
}

# 5. NAT Gateway for Kubernetes Cluster Private Subnet
resource "samsungcloudplatform_nat_gateway" "nat" {
  subnet_id  = samsungcloudplatform_subnet.k8s_subnet.id
  depends_on = [samsungcloudplatform_subnet.k8s_subnet]
}

# 6. Load Balancer
resource "samsungcloudplatform_load_balancer" "lb" {
  vpc_id     = samsungcloudplatform_vpc.mz_vpc.id
  name        = "${var.prefix}LB"
  size       = var.load_balancer_size
  cidr_ipv4  = var.lb_cidr_ipv4
  depends_on = [samsungcloudplatform_vpc.mz_vpc]
}

# 7. File Storage
resource "samsungcloudplatform_file_storage" "storage" {
  file_storage_name     = var.file_storage_name
  disk_type             = var.file_storage_disk_type
  file_storage_protocol = var.file_storage_protocol
  product_names         = var.file_storage_product_names
  service_zone_id       = data.samsungcloudplatform_region.region.id
  depends_on            = [samsungcloudplatform_vpc.mz_vpc]
}

# 8. Internet Gateway Firewall Rules

data "samsungcloudplatform_firewall" "igw_firewall" {
  vpc_id    = samsungcloudplatform_vpc.mz_vpc.id
  target_id = samsungcloudplatform_internet_gateway.igw.id
  depends_on = [samsungcloudplatform_internet_gateway.igw]
}

resource "samsungcloudplatform_firewall_rule" "igw_rule_a_https_inbound" {
  firewall_id                = data.samsungcloudplatform_firewall.igw_firewall.id
  direction                  = "IN"
  action                     = "ALLOW"
  enabled                    = true
  source_addresses_ipv4      = ["0.0.0.0/0"]
  destination_addresses_ipv4 = [var.lb_cidr_ipv4]
  service {
    type  = "TCP"
    value = "443"
  }
  description = "Inbound HTTPS from Internet to LB"
  depends_on  = [samsungcloudplatform_internet_gateway.igw]
}

resource "samsungcloudplatform_firewall_rule" "igw_rule_b_ssh_inbound" {
  firewall_id                = data.samsungcloudplatform_firewall.igw_firewall.id
  direction                  = "IN"
  action                     = "ALLOW"
  enabled                    = true
  source_addresses_ipv4      = [var.user_public_ip]
  destination_addresses_ipv4 = [var.bastion_subnet_cidr]
  service {
    type  = "TCP"
    value = "22"
  }
  description = "Inbound SSH from Lab PC to Bastion"
  depends_on  = [samsungcloudplatform_firewall_rule.igw_rule_a_https_inbound]
}

resource "samsungcloudplatform_firewall_rule" "igw_rule_c_http_outbound" {
  firewall_id                = data.samsungcloudplatform_firewall.igw_firewall.id
  direction                  = "OUT"
  action                     = "ALLOW"
  enabled                    = true
  source_addresses_ipv4      = [var.bastion_subnet_cidr]
  destination_addresses_ipv4 = ["0.0.0.0/0"]
  service {
    type  = "TCP"
    value = "80"
  }
  service {
    type  = "TCP"
    value = "443"
  }
  description = "Outbound HTTP/HTTPS from Bastion to Internet"
  depends_on  = [samsungcloudplatform_firewall_rule.igw_rule_b_ssh_inbound]
}

resource "samsungcloudplatform_firewall_rule" "igw_rule_d_k8s_outbound" {
  firewall_id                = data.samsungcloudplatform_firewall.igw_firewall.id
  direction                  = "OUT"
  action                     = "ALLOW"
  enabled                    = true
  source_addresses_ipv4      = [var.k8s_subnet_cidr]
  destination_addresses_ipv4 = ["0.0.0.0/0"]
  service {
    type  = "TCP"
    value = "80"
  }
  service {
    type  = "TCP"
    value = "443"
  }
  service {
    type  = "TCP"
    value = "8443"
  }
  description = "Outbound HTTP/HTTPS/8443 from K8s to Internet"
  depends_on  = [samsungcloudplatform_firewall_rule.igw_rule_c_http_outbound]
}

# 9. Security Group for Bastion VM 
resource "samsungcloudplatform_security_group" "bastion_sg" {
  vpc_id      = samsungcloudplatform_vpc.mz_vpc.id
  name        = var.bastion_sg_name
  is_loggable = var.bastion_sg_loggable
  depends_on  = [samsungcloudplatform_vpc.mz_vpc]
}

resource "samsungcloudplatform_security_group_rule" "bastion_rule_g_ssh_inbound" {
  security_group_id = samsungcloudplatform_security_group.bastion_sg.id
  direction         = "in"
  addresses_ipv4    = [var.user_public_ip]
  service {
    type  = "TCP"
    value = "22"
  }
  description = "Inbound SSH from Lab PC"
  depends_on  = [samsungcloudplatform_security_group.bastion_sg]
}

resource "samsungcloudplatform_security_group_rule" "bastion_rule_h_http_outbound" {
  security_group_id = samsungcloudplatform_security_group.bastion_sg.id
  direction         = "out"
  addresses_ipv4    = ["0.0.0.0/0"]
  service {
    type  = "TCP"
    value = "80"
  }
  service {
    type  = "TCP"
    value = "443"
  }
  description = "Outbound HTTP/HTTPS to Internet"
  depends_on  = [samsungcloudplatform_security_group_rule.bastion_rule_g_ssh_inbound]
}

# 10. Security Group for Kubernetes Cluster
resource "samsungcloudplatform_security_group" "k8s_sg" {
  vpc_id      = samsungcloudplatform_vpc.mz_vpc.id
  name        = var.k8s_sg_name
  is_loggable = var.k8s_sg_loggable
  depends_on  = [samsungcloudplatform_vpc.mz_vpc]
}

resource "samsungcloudplatform_security_group_rule" "k8s_rule_f_outbound" {
  security_group_id = samsungcloudplatform_security_group.k8s_sg.id
  direction         = "out"
  addresses_ipv4    = ["0.0.0.0/0"]
  service {
    type  = "TCP"
    value = "80"
  }
  service {
    type  = "TCP"
    value = "443"
  }
  service {
    type  = "TCP"
    value = "8443"
  }
  description = "Outbound HTTP/HTTPS/8443 to Internet"
  depends_on  = [samsungcloudplatform_security_group.k8s_sg]
}

# 11. Key Pair for Bastion VM
resource "samsungcloudplatform_key_pair" "bastion_keypair" {
  key_pair_name = var.bastion_key_pair_name
}

# 12. Virtual Server for Bastion
resource "samsungcloudplatform_virtual_server" "bastion_vm" {
  virtual_server_name = var.bastion_server_name
  key_pair_id         = samsungcloudplatform_key_pair.bastion_keypair.id

  server_type = "s1v1m2"
  image_id    = data.samsungcloudplatform_standard_image.bastion_image.id
  vpc_id      = samsungcloudplatform_vpc.mz_vpc.id
  subnet_id   = samsungcloudplatform_subnet.bastion_subnet.id

  state = "RUNNING"

  os_storage_name      = var.bastion_os_storage_name
  os_storage_size_gb   = var.bastion_os_storage_size_gb
  os_storage_encrypted = false

  security_group_ids = [samsungcloudplatform_security_group.bastion_sg.id]

  nat_enabled = true

  depends_on = [
    samsungcloudplatform_vpc.mz_vpc,
    samsungcloudplatform_internet_gateway.igw,
    samsungcloudplatform_subnet.bastion_subnet,
    samsungcloudplatform_security_group.bastion_sg
  ]
}

# 13. Kubernetes Engine
resource "samsungcloudplatform_kubernetes_engine" "cluster" {
  count = var.create_kubernetes_cluster ? 1 : 0

  name        = "${var.prefix}k8sdev"
  kubernetes_version = var.k8s_version

  # Network
  vpc_id            = samsungcloudplatform_vpc.mz_vpc.id
  subnet_id         = samsungcloudplatform_subnet.k8s_subnet.id
  security_group_id = samsungcloudplatform_security_group.k8s_sg.id

  # File Storage
  volume_id = samsungcloudplatform_file_storage.storage.id

  # Load Balancer
  load_balancer_id = samsungcloudplatform_load_balancer.lb.id

  depends_on = [
    samsungcloudplatform_subnet.k8s_subnet,
    samsungcloudplatform_security_group.k8s_sg,
    samsungcloudplatform_load_balancer.lb,
    samsungcloudplatform_file_storage.storage
  ]
}

# 14. Kubernetes Node Pool
resource "samsungcloudplatform_kubernetes_node_pool" "node_pool" {
  for_each = var.create_kubernetes_cluster ? { for idx, pool in var.k8s_node_pools : idx => pool } : {}

  engine_id = samsungcloudplatform_kubernetes_engine.cluster[0].id
  name      = each.value.node_pool_name
  image_id  = each.value.image_id

  # Scale
  scale_name = each.value.scale_name

  # Storage
  storage_name    = each.value.storage_name
  storage_size_gb = each.value.storage_size_gb
  encrypt_enabled = each.value.encrypt_enabled

  # Node Count
  desired_node_count = each.value.desired_node_count

  # Auto Scaling
  auto_scale     = each.value.auto_scale
  min_node_count = each.value.auto_scale ? each.value.min_node_count : null
  max_node_count = each.value.auto_scale ? each.value.max_node_count : null
}
