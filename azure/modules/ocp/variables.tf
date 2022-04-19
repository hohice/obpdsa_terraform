variable "location" {
  default = "chinanorth3"
}

variable "rg_name" {
  default = "myTFResourceGroup"
}

variable "avset_id" {
  default = ""
}

variable "internal_address_prefixes" {
  default = ""
}

variable "internal_inet_id" {
  default = ""
}

variable "prefix" {
  default = "obcluster"
}

variable "environment" {
  default = "dev"
}

variable "os_publisher" {
  default = "OpenLogic"
}

variable "os_offer" {
  default = "CentOS"
}

variable "os_sku" {
  default = "7.7"
}

variable "os_version" {
  default = "latest"
}

variable "ocp_vm_type" {
  default = "Standard_E16s_v4"
}


variable "ocp_vm_prefix" {
  default = "ocp"
}


variable "ocp_instance_count" {
  default = 1
}


variable "managed_disk_type" {
  default = "Premium_LRS"
}

variable "os_disk_size_GB" {
  default = 100
}

variable "managed_disk_size_GB" {
  default = 1024
}


variable "vm_admin_password" {
  default = "OBadmin_123"
}

variable "vm_admin_username" {
  default = "adminUsername"
}





