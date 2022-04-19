
resource "azurerm_linux_virtual_machine_scale_set" "observer" {
  resource_group_name = var.rg_name
  location            = var.location
  availability_set_id = var.avset_id
  name                = "${var.ob_vm_prefix}-vm"
  sku                 = var.ob_vm_type
  instances           = var.ob_instance_count
  


  admin_username                  = var.vm_admin_username
  admin_password                  = var.vm_admin_password
  disable_password_authentication = false
  user_data                       = file("${path.module}/../../pkg/userdata/azure/ocp/cloud_init.txt")


  source_image_reference {
    publisher = var.os_publisher
    offer     = var.os_offer
    sku       = var.os_sku
    version   = var.os_version
  }

  os_disk {
    name                 = "ob_os_disk0"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.os_disk_size_GB
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = var.internal_inet_id
    }
  }

  data_disk {
    lun                  = 1
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb         = var.managed_disk_size_GB

  }

  data_disk {
    lun                  = 2
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb         = var.managed_disk_size_GB

  }

  data_disk {
    lun                  = 3
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb         = var.managed_disk_size_GB

  }

  data_disk {
    lun                  = 4
    caching              = "ReadWrite"
    storage_account_type = var.managed_disk_type
    disk_size_gb         = var.managed_disk_size_GB

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
    script = file("${path.module}/../../pkg/userdata/azure/ob/init_ob.sh")
  }


  tags = {
    environment = var.environment
    role        = var.ob_vm_prefix
  }
}
