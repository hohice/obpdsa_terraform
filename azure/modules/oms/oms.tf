

resource "azurerm_network_security_group" "oms" {
  name                = "oms"
  location            = var.location
  resource_group_name = var.rg_name
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "http"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "8080"
    destination_address_prefix = var.internal_address_prefixes
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


resource "azurerm_public_ip" "oms_public" {
  name                = "${var.oms_vm_prefix}-public-nic"
  resource_group_name = var.rg_name
  location            = var.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "oms_public_inet" {
  name                = "${var.oms_vm_prefix}-nic"
  resource_group_name = var.rg_name
  location            = var.location

  ip_configuration {
    name                          = "${var.oms_vm_prefix}-nic-primary"
    subnet_id                     = var.internal_inet_id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.oms_public.id
  }

}

resource "azurerm_network_interface_security_group_association" "oms_public_inet" {
  network_interface_id      = azurerm_network_interface.oms_public_inet.id
  network_security_group_id = azurerm_network_security_group.oms.id
}

resource "azurerm_virtual_machine" "oms" {
  name                  = "${var.oms_vm_prefix}-vm"
  resource_group_name = var.rg_name
  location            = var.location
  availability_set_id = var.avset_id
  vm_size               = var.oms_vm_type
  
  network_interface_ids = ["${azurerm_network_interface.ocp_public_inet.id}"]
  user_data             = file("${path.module}/../../pkg/userdata/azure/oms/cloud_init.txt")

  storage_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }


  storage_os_disk {
    name              = "oms_os_disk0"
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
    name              = "${var.oms_vm_prefix}-edisk01"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 1
    name              = "${var.oms_vm_prefix}-edisk02"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 2
    name              = "${var.oms_vm_prefix}-edisk03"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }
  storage_data_disk {
    lun               = 3
    name              = "${var.oms_vm_prefix}-edisk04"
    caching           = "ReadWrite"
    create_option     = "Empty"
    disk_size_gb      = var.managed_disk_size_GB
    managed_disk_type = var.managed_disk_type
  }

  connection {
    type        = "ssh"
    user        = "opsadmin"
    host        = azurerm_public_ip.oms_public.fqdn
    private_key = file("${path.module}/../../pkg/ssh/id_rsa")
  }

  provisioner "file" {
    source      = "${path.module}/../../pkg/antman/t-oceanbase-antman-1.3.8-1930157.alios7.x86_64.rpm"
    destination = "/home/opsadmin/t-oceanbase-antman-1.3.8-1930157.alios7.x86_64.rpm"
  }

  provisioner "remote-exec" {
    script = file("${path.module}/../../pkg/userdata/azure/oms/init_single_oms.sh")
  }


  tags = {
    environment = var.environment
    role        = var.oms_vm_prefix
  }
}