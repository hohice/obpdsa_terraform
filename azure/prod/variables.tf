variable "resource_location" {
  default = "chinanorth3"
}

variable "resource_group_name" {
  default = "myTFResourceGroup"
}

variable "resource_vnet_name" {
  default = "ob-resource-vnet"
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
  default = "Standard_E20s_v4"
}


variable "ocp_vm_prefix" {
  default = "ocp"
}


variable "ocp_instance_count" {
  default = 1
}

variable "oms_vm_type" {
  default = "Standard_E20s_v4"
}


variable "oms_vm_prefix" {
  default = "oms"
}

variable "ob_vm_type" {
  default = "Standard_E20s_v4"
}


variable "oms_instance_count" {
  default = 1
}

variable "ob_vm_prefix" {
  default = "observer"
}


variable "ob_instance_count" {
  default = 3
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

variable "admin_username" {
  default = "adminUsername"
}

variable "admin_password" {
  default = "OBadmin_123"
}





