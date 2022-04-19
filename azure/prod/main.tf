resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.resource_location
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


resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}avset"
  location                     = azurerm_resource_group.main.location
  resource_group_name          = azurerm_resource_group.main.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
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
}

resource "azurerm_network_interface" "ocp" {
  count               = var.ocp_instance_count
  name                = "${var.ocp_vm_prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.ocp_vm_prefix}-nic${count.index}-primary"
    subnet_id                     = azurerm_subnet.internal.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
  }
}


resource "azurerm_network_interface" "oms" {
  count               = var.oms_instance_count
  name                = "${var.oms_vm_prefix}-nic${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "${var.oms_vm_prefix}-nic${count.index}-primary"
    subnet_id                     = azurerm_subnet.internal.id
    primary                       = true
    private_ip_address_allocation = "Dynamic"
  }
}





## lb for obproxy
## resource "azurerm_public_ip" "obpip" {
##   name                = "${var.prefix}-obpip"
##   resource_group_name = azurerm_resource_group.main.name
##   location            = azurerm_resource_group.main.location
##   allocation_method   = "Dynamic"
## }
## 
## resource "azurerm_lb" "obproxy" {
##   name                = "${var.prefix}-lb"
##   location            = azurerm_resource_group.main.location
##   resource_group_name = azurerm_resource_group.main.name
## 
##   frontend_ip_configuration {
##     name                 = "PublicIPAddress"
##     public_ip_address_id = azurerm_public_ip.obpip.id
##   }
## }
## 
## resource "azurerm_lb_backend_address_pool" "obproxy" {
##   resource_group_name = azurerm_resource_group.main.name
##   loadbalancer_id     = azurerm_lb.obproxy.id
##   name                = "BackEndAddressPool"
## }
## 
## resource "azurerm_lb_nat_rule" "obproxy" {
##   resource_group_name            = azurerm_resource_group.main.name
##   loadbalancer_id                = azurerm_lb.obproxy.id
##   name                           = "OBPAccess"
##   protocol                       = "Tcp"
##   frontend_port                  = 2883
##   backend_port                   = 2883
##   frontend_ip_configuration_name = azurerm_lb.obproxy.frontend_ip_configuration[0].name
## }
## 
## resource "azurerm_network_interface_backend_address_pool_association" "obproxy" {
##   count                   = local.instance_count
##   backend_address_pool_id = azurerm_lb_backend_address_pool.obproxy.id
##   ip_configuration_name   = "primary"
##   network_interface_id    = element(azurerm_network_interface.ob.*.id, count.index)
## }



resource "azurerm_linux_virtual_machine" "alvm_ocp" {
  count                           = var.ocp_instance_count
  name                            = "${var.ocp_vm_prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.ocp_vm_type
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  availability_set_id             = azurerm_availability_set.avset.id
  custom_data                     = base64encode("Hello World!")
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.ocp[count.index].id,
  ]


  os_disk {
    name                 = "myosdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_GB
  }


  storage_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = var.managed_disk_size_GB
  }

  tags = {
    environment = var.environment
    role        = var.ocp_vm_prefix
  }
}


resource "azurerm_linux_virtual_machine" "alvm_oms" {
  count                           = var.oms_instance_count
  name                            = "${var.oms_vm_prefix}-vm"
  computer_name                   = "hostname"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.oms_vm_type
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  availability_set_id             = azurerm_availability_set.avset.id
  custom_data                     = base64encode("Hello World!")
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.oms[count.index].id,
  ]

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }


  os_disk {
    name    = "myosdisk1"
    caching = "ReadWrite"
    # create_option     = "FromImage"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_GB
  }


  storage_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = var.disk_size_gb
  }

  tags = {
    environment = var.environment
    role        = var.oms_vm_prefix
  }
}

## resource "azurerm_linux_virtual_machine" "observer" {
##   count                           = var.ob_instance_count
##   name                            = "${var.ob_vm_prefix}-vm${count.index}"
##   resource_group_name             = azurerm_resource_group.main.name
##   location                        = azurerm_resource_group.main.location
##   size                            = var.ob_vm_type
##   admin_username                  = var.admin_username
##   admin_password                  = var.admin_password
##   availability_set_id             = azurerm_availability_set.avset.id
##   disable_password_authentication = false
##   computer_name                   = "hostname"
##   ## disable_password_authentication = true
##   ## admin_ssh_key {
##   ##   path     = "/home/myadmin/.ssh/authorized_keys"
##   ##   key_data = file("~/.ssh/demo_key.pub")
##   ## }
## 
##   network_interface_ids = [
##     azurerm_network_interface.ob[count.index].id,
##   ]
## 
##   source_image_reference {
##     publisher = var.os_publisher
##     offer     = var.os_offer
##     sku       = var.os_sku
##     version   = var.os_version
##   }
## 
## 
##   os_disk {
##     name    = "myosdisk1"
##     caching = "ReadWrite"
##     storage_account_type = "Standard_LRS"
##     disk_size_gb = var.os_disk_size_GB
##   }
## 
##   storage_data_disk {
##     lun               = 0
##     name              = "${var.ob_vm_prefix}-vm${count.index}-edisk0"
##     createOption      = "Attach"
##     deleteOption      = "Detach"
##     caching           = "ReadWrite"
##     toBeDetached      = false
##     managed_disk_type = var.managed_disk_type
##     diskSizeGB        = var.managed_disk_size_GB
##   }
## 
##   storage_data_disk {
##     lun               = 1
##     name              = "${var.ob_vm_prefix}-vm${count.index}-edisk1"
##     createOption      = "Attach"
##     deleteOption      = "Detach"
##     caching           = "ReadWrite"
##     toBeDetached      = false
##     managed_disk_type = var.managed_disk_type
##     diskSizeGB        = var.managed_disk_size_GB
##   }
## 
##   storage_data_disk {
##     lun               = 2
##     name              = "${var.ob_vm_prefix}-vm${count.index}-edisk2"
##     createOption      = "Attach"
##     deleteOption      = "Detach"
##     caching           = "ReadWrite"
##     toBeDetached      = false
##     managed_disk_type = var.managed_disk_type
##     diskSizeGB        = var.managed_disk_size_GB
##   }
## 
##   storage_data_disk {
##     lun               = 3
##     name              = "${var.ob_vm_prefix}-vm${count.index}-edisk3"
##     createOption      = "Attach"
##     deleteOption      = "Detach"
##     caching           = "ReadWrite"
##     toBeDetached      = false
##     managed_disk_type = var.managed_disk_type
##     diskSizeGB        = var.managed_disk_size_GB
##   }
## 
##   provisioner "remote-exec" {
##     inline = [
##       "ls -la /tmp",
##     ]
## 
##     connection {
##       host     = self.public_ip_address
##       user     = self.admin_username
##       password = self.admin_password
##     }
##   }
## 
##   tags = {
##     environment = var.environment
##     role        = var.ob_vm_prefix
##   }
## }


resource "azurerm_linux_virtual_machine_scale_set" "observer" {
  instances                       = var.ob_instance_count
  name                            = "${var.ob_vm_prefix}-vm${instances.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  sku                             = var.ob_vm_type
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  availability_set_id             = azurerm_availability_set.avset.id
  disable_password_authentication = false
  computer_name                   = "hostname"


  ## admin_ssh_key {
  ##   username   = "adminuser"
  ##   public_key = file("~/.ssh/id_rsa.pub")
  ## }

  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }


  os_disk {
    name                 = "myosdisk1"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_GB
  }

  storage_data_disk {
    lun               = 0
    name              = "${var.ob_vm_prefix}-vm${count.index}-edisk0"
    createOption      = "Attach"
    deleteOption      = "Detach"
    caching           = "ReadWrite"
    toBeDetached      = false
    managed_disk_type = var.managed_disk_type
    diskSizeGB        = var.managed_disk_size_GB
  }

  storage_data_disk {
    lun               = 1
    name              = "${var.ob_vm_prefix}-vm${count.index}-edisk1"
    createOption      = "Attach"
    deleteOption      = "Detach"
    caching           = "ReadWrite"
    toBeDetached      = false
    managed_disk_type = var.managed_disk_type
    diskSizeGB        = var.managed_disk_size_GB
  }

  storage_data_disk {
    lun               = 2
    name              = "${var.ob_vm_prefix}-vm${count.index}-edisk2"
    createOption      = "Attach"
    deleteOption      = "Detach"
    caching           = "ReadWrite"
    toBeDetached      = false
    managed_disk_type = var.managed_disk_type
    diskSizeGB        = var.managed_disk_size_GB
  }

  storage_data_disk {
    lun               = 3
    name              = "${var.ob_vm_prefix}-vm${count.index}-edisk3"
    createOption      = "Attach"
    deleteOption      = "Detach"
    caching           = "ReadWrite"
    toBeDetached      = false
    managed_disk_type = var.managed_disk_type
    diskSizeGB        = var.managed_disk_size_GB
  }

  network_interface {
    name    = "${var.ob_vm_prefix}-nic-primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }

}