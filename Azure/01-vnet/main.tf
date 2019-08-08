### Spin up Azure infrastructure

# New Resource Group
resource "azurerm_resource_group" "test01-rg" {
  name     = "${var.prefix}-resources"
  location = "${var.location}"
}

# New storage account
resource "azurerm_storage_account" "test01-cgf-elb" {
  name                     = "${var.prefix}test01storageacct"
  resource_group_name      = "${azurerm_resource_group.test01-rg.name}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# New standard public ip addresses
resource "azurerm_public_ip" "test01-primary-pip" {
  name                = "${var.prefix}-ELB-PubIP-Primary"
  location            = "${azurerm_resource_group.test01-rg.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "test01-secondary-pip" {
  name                = "${var.prefix}-ELB-PubIP-Secondary"
  location            = "${azurerm_resource_group.test01-rg.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
  sku                 = "Standard"
  allocation_method   = "Static"
}

# New standard load balancer - external
resource "azurerm_lb" "test01-cgf-elb" {
  name                = "${var.prefix}-CGF-ELB"
  location            = "${azurerm_resource_group.test01-rg.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
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

# New standard load balancer - internal
resource "azurerm_lb" "test01-cgf-ilb" {
  name                = "${var.prefix}-CGF-ILB"
  location            = "${azurerm_resource_group.test01-rg.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
  sku                 = "Standard"
  
  frontend_ip_configuration {
    name                          = "ILB-IP-Address"
    private_ip_address            = "${var.ilbIpAddress}"
    private_ip_address_allocation = "static"
    subnet_id                     = "${azurerm_subnet.fwsubnet.id}"
  }
}

# New virtual network
resource "azurerm_virtual_network" "test01" {
  name                = "${var.prefix}-VNet"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
  location            = "${azurerm_resource_group.test01-rg.location}"
  address_space       = ["${var.addrSpace}"]
}

# New subnets
resource "azurerm_subnet" "fwsubnet" {
  name                 = "fwsubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01-rg.name}"
  address_prefix       = "${var.fwSubnetCIDR}"
}

resource "azurerm_subnet" "websubnet" {
  name                 = "websubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01-rg.name}"
  address_prefix       = "${var.webSubnetCIDR}"
}

resource "azurerm_subnet" "appsubnet" {
  name                 = "appsubnet"
  virtual_network_name = "${azurerm_virtual_network.test01.name}"
  resource_group_name  = "${azurerm_resource_group.test01-rg.name}"
  address_prefix       = "${var.appSubnetCIDR}"
}

# New NSG
resource "azurerm_network_security_group" "test01" {
  name                = "${var.prefix}-nsg"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"
  location            = "${azurerm_resource_group.test01-rg.location}"
}

# New route tables for standard LBs
resource "azurerm_route_table" "test01" {
  name                          = "${var.prefix}-routetable-websubnet"
  location                      = "${azurerm_resource_group.test01-rg.location}"
  resource_group_name           = "${azurerm_resource_group.test01-rg.name}"
  disable_bgp_route_propagation = true
}

resource "azurerm_route_table" "test01-webroute" {
  name                = "${var.prefix}-RT-WebSubnet"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"

  route {
    name                   = "${var.prefix}-WebToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

  route {
    name                   = "${var.prefix}-WebToAppSubnet"
    address_prefix         = "${var.appSubnetCIDR}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

}

resource "azurerm_route_table" "test01-approute" {
  name                = "${var.prefix}-RT-AppSubnet"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.test01-rg.name}"

  route {
    name                   = "${var.prefix}-AppToInternet"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

  route {
    name                   = "${var.prefix}-AppToWebSubnet"
    address_prefix         = "${var.webSubnetCIDR}"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "${var.ilbIpAddress}"
  }

}

# Availability set for CGFs
resource "azurerm_availability_set" "test01-cgf-as" {
  name                         = "${var.prefix}-CGF-AS"
  location                     = "${var.location}"
  managed                      = true
  resource_group_name          = "${azurerm_resource_group.test01-rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
}

# Availability set for WAFs
resource "azurerm_availability_set" "test01-waf-as" {
  name                         = "${var.prefix}-WAF-AS"
  location                     = "${var.location}"
  managed                      = true
  resource_group_name          = "${azurerm_resource_group.test01-rg.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
}
