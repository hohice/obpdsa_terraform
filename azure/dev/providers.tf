# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = "72876a1d-e580-4d77-b3a5-04e578a0a36a"
  tenant_id       = "43f0b50f-1501-4ff9-9923-ed46f1aea0b8"
  client_id       = "860dda31-f37b-4709-8a16-444c911cf3e9"
  client_secret   = "TG~8onVCugefLvmy~BLk1iCO5kACSlJAwm"

}
