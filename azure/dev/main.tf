resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_location
}


resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}avset"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}


resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}


resource "azurerm_network_security_group" "ocp" {
  name                = "ocp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "http"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "8080"
    destination_address_prefix = azurerm_subnet.internal.address_prefixes
  }

  security_rule {
    name                       = "allow-internal-ssh"
    description                = "Allow Internal SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}


resource "azurerm_public_ip" "ocp_public" {
  name                = "${var.ocp_vm_prefix}-public-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "ocp_public_inet" {
  name                = "${var.ocp_vm_prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.ocp_vm_prefix}-nic-primary"
    subnet_id                     = azurerm_subnet.internal.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ocp_public.id
  }

}

resource "azurerm_network_interface_security_group_association" "ocp_public_inet" {
  network_interface_id      = azurerm_network_interface.ocp_public_inet.id
  network_security_group_id = azurerm_network_security_group.ocp.id
}



resource "azurerm_virtual_machine" "ocp" {
  name                  = "${var.ocp_vm_prefix}-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  vm_size               = var.ocp_vm_type
  availability_set_id   = azurerm_availability_set.avset.id
  network_interface_ids = ["${azurerm_network_interface.ocp_public_inet.id}"]
  user_data             = file("${path.module}/../../pkg/userdata/azure/ocp/cloud_init.txt")

  storage_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }


  storage_os_disk {
    name              = "ocp_os_disk0"
    os_type           = "Linux"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = var.os_disk_size_GB
  }

  os_profile {
    computer_name     = "hostname"
    vm_admin_username = var.vm_admin_username
    vm_admin_password = var.vm_admin_password
  }

  # os_profile_linux_config {
  #   disable_password_authentication = true
  #   ssh_keys {
  #     path     = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
  #     key_data = file("${path.module}/../../pkg/ssh/id_rsa.pub")
  #   }
  # }

  storage_data_disk {
    lun               = 0
    name              = "${var.ocp_vm_prefix}-edisk01"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 1
    name              = "${var.ocp_vm_prefix}-edisk02"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 2
    name              = "${var.ocp_vm_prefix}-edisk03"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 3
    name              = "${var.ocp_vm_prefix}-edisk04"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }

  connection {
    type        = "ssh"
    user        = "opsadmin"
    host        = azurerm_public_ip.ocp_public.fqdn
    private_key = file("${path.module}/../../pkg/ssh/id_rsa")
  }

  provisioner "file" {
    source      = "${path.module}/../../pkg/antman/t-oceanbase-antman-1.3.8-1930157.alios7.x86_64.rpm"
    destination = "/home/opsadmin/t-oceanbase-antman-1.3.8-1930157.alios7.x86_64.rpm"
  }

  provisioner "remote-exec" {
    script = file("${path.module}/../../pkg/userdata/azure/ocp/install_ocp.sh")
  }


  tags = {
    environment = var.environment
    role        = var.ocp_vm_prefix
  }
}
