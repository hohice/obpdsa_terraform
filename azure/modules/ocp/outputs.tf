output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.ocp_public.fqdn}"
}

output "ocp_http_url" {
  value = "http://{azurerm_public_ip.ocp_public.fqdn}:8080"
}

