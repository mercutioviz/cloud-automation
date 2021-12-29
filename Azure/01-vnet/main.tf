### Spin up Azure infrastructure
# Features Block
provider "azurerm" {
    features {}
}

# New Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.prefix != "" ? "${var.prefix}-resources" : "resources"
  location = "${var.location}"
}

# New storage account
resource "azurerm_storage_account" "cgf-elb" {
  name                     = var.prefix != "" ? "${var.prefix}test01storageacct" : "test01storageacct"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# New standard public ip addresses
resource "azurerm_public_ip" "primary-pip" {
  name                = var.prefix != "" ? "${var.prefix}-ELB-PubIP-Primary" : "ELB-PubIP-Primary"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "secondary-pip" {
  name                = var.prefix != "" ? "${var.prefix}-ELB-PubIP-Secondary" : "ELB-PubIP-Secondary"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

# New standard load balancer - external
resource "azurerm_lb" "cgf-elb" {
  name                = var.prefix != "" ? "${var.prefix}-CGF-ELB" : "CGF-ELB"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                 = "PrimaryPIP"
    public_ip_address_id = "${azurerm_public_ip.primary-pip.id}"
  }

  frontend_ip_configuration {
    name                 = "SecondaryPIP"
    public_ip_address_id = "${azurerm_public_ip.secondary-pip.id}"
  }
}

# New standard load balancer - internal
resource "azurerm_lb" "cgf-ilb" {
  name                = var.prefix != "" ? "${var.prefix}-CGF-ILB" : "CGF-ILB"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                          = "ILB-IP-Address"
    private_ip_address            = "${var.ilbIpAddress}"
    private_ip_address_allocation = "static"
    subnet_id                     = "${azurerm_subnet.fwsubnet.id}"
  }
}

# New virtual network
resource "azurerm_virtual_network" "VNet01" {
  name                = var.prefix != "" ? "${var.prefix}-VNet" : "VNet"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
  address_space       = ["${var.addrSpace}"]
}

# New subnets
resource "azurerm_subnet" "fwsubnet" {
  name                 = "fwsubnet"
  virtual_network_name = "${azurerm_virtual_network.VNet01.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.fwSubnetCIDR}"]
}

resource "azurerm_subnet" "websubnet" {
  name                 = "websubnet"
  virtual_network_name = "${azurerm_virtual_network.VNet01.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.webSubnetCIDR}"]
}

resource "azurerm_subnet" "appsubnet" {
  name                 = "appsubnet"
  virtual_network_name = "${azurerm_virtual_network.VNet01.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefixes     = ["${var.appSubnetCIDR}"]
}

# New NSGs
resource "azurerm_network_security_group" "cgf-nsg" {
  name                = var.prefix != "" ? "${var.prefix}-CGF-NSG" : "CGF-NSG"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
}

resource "azurerm_network_security_group" "waf-nsg" {
  name                = var.prefix != "" ? "${var.prefix}-WAF-NSG" : "WAF-NSG"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${azurerm_resource_group.rg.location}"
}

# New route tables for standard LBs
resource "azurerm_route_table" "rt-lbroute" {
  name                          = var.prefix != "" ? "${var.prefix}-routetable-websubnet" : "routetable-websubnet"
  location                      = "${azurerm_resource_group.rg.location}"
  resource_group_name           = "${azurerm_resource_group.rg.name}"
  disable_bgp_route_propagation = true
}

resource "azurerm_route_table" "rt-webroute" {
  name                = var.prefix != "" ? "${var.prefix}-RT-WebSubnet" : "RT-WebSubnet"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  route {
    name                   = var.prefix != "" ? "${var.prefix}-WebToInternet" : "WebToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

  route {
    name                   = var.prefix != "" ? "${var.prefix}-WebToAppSubnet" : "WebToAppSubnet"
    address_prefix         = "${var.appSubnetCIDR}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

}

resource "azurerm_route_table" "rt-approute" {
  name                = var.prefix != "" ? "${var.prefix}-RT-AppSubnet" : "RT-AppSubnet"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  route {
    name                   = var.prefix != "" ? "${var.prefix}-AppToInternet" : "AppToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

  route {
    name                   = var.prefix != "" ? "${var.prefix}-AppToWebSubnet" : "AppToWebSubnet"
    address_prefix         = "${var.webSubnetCIDR}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

}

