terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.26.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "9734ed68-621d-47ed-babd-269110dbacb1"
  client_id       = "e2e3d417-66e8-4f66-a6c2-3f14563a781f"
  client_secret   = "GWI8Q~85SsaQhH_PwK_9tz_OXi9UqcBCf3c.CaiL"
  tenant_id       = "84f1e4ea-8554-43e1-8709-f0b8589ea118"
  
  # Add this line to disable automatic registration
  resource_provider_registrations = "none"
  features {}
}

locals {
  resource_group = "1-5604d3fa-playground-sandbox"
  location       = "West US"  
}

resource "azurerm_resource_group" "app_grp" {
  name     = local.resource_group
  location = local.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "network_interface"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "Azure@123"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip"
  location            = local.location
  resource_group_name = local.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "host" {
  name                = "bastion"
  location            = local.location
  resource_group_name = local.resource_group

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.pip.id
  }
}