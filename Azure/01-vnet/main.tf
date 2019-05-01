### Spin up Azure infrastructure

# New Resource Group
resource "azurerm_resource_group" "test01" {
  name     = "${var.prefix}-resources"
  location = "${var.location}"
}

# New storage account
resource "azurerm_storage_account" "test01" {
  name                     = "test01storageacct"
  resource_group_name      = "${azurerm_resource_group.test01.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# New standard public ip addresses
resource "azurerm_public_ip" "test01-primary-pip" {
  name                = "ELB-PubIP-Primary"
  location            = "${azurerm_resource_group.test01.location}"
  resource_group_name = "${azurerm_resource_group.test01.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "test01-secondary-pip" {
  name                = "ELB-PubIP-Secondary"
  location            = "${azurerm_resource_group.test01.location}"
  resource_group_name = "${azurerm_resource_group.test01.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

# New standard load balancer
resource "azurerm_lb" "test01" {
  name                = "CGF-ELB"
  location            = "${azurerm_resource_group.test01.location}"
  resource_group_name = "${azurerm_resource_group.test01.name}"
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                 = "PrimaryPIP"
    public_ip_address_id = "${azurerm_public_ip.test01-primary-pip.id}"
  }

  frontend_ip_configuration {
    name                 = "SecondaryPIP"
    public_ip_address_id = "${azurerm_public_ip.test01-secondary-pip.id}"
  }
}

# New virtual network
resource "azurerm_virtual_network" "test01" {
  name                = "${var.prefix}-VNet"
  resource_group_name = "${azurerm_resource_group.test01.name}"
  location            = "${azurerm_resource_group.test01.location}"
  address_space       = ["${var.addrSpace}"]
}

# New subnets
resource "azurerm_subnet" "fwsubnet" {
  name                 = "fwsubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01.name}"
  address_prefix       = "10.99.1.0/24"
}

resource "azurerm_subnet" "websubnet" {
  name                 = "websubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01.name}"
  address_prefix       = "10.99.2.0/24"
}

resource "azurerm_subnet" "appsubnet" {
  name                 = "appsubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01.name}"
  address_prefix       = "10.99.3.0/24"
}

# New NSG
resource "azurerm_network_security_group" "test01" {
  name                = "${var.prefix}-nsg"
  resource_group_name = "${azurerm_resource_group.test01.name}"
  location            = "${azurerm_resource_group.test01.location}"
}

# New route tables for standard LBs
resource "azurerm_route_table" "test01" {
  name                          = "routetable-websubnet"
  location                      = "${azurerm_resource_group.test01.location}"
  resource_group_name           = "${azurerm_resource_group.test01.name}"
  disable_bgp_route_propagation = true
}