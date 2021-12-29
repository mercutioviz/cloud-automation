variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = ""
}

variable "location" {
  description = "The Azure location where all resources in this example should be created"
  default = "southcentralus"
}

variable "addrSpace" {
  description = "The CIDR block for the VNet to be created."
  default = "10.99.0.0/16"
}

variable "fwSubnetCIDR" {
  description = "CIDR of the CGF subnet"
  default = "10.99.0.0/24"
}

variable "webSubnetCIDR" {
  description = "CIDR of the web/WAF subnet"
  default = "10.99.1.0/24"
}

variable "appSubnetCIDR" {
  description = "CIDR of the app subnet"
  default = "10.99.2.0/24"
}

variable "ilbIpAddress" {
  description = "IP Address of internal standard LB"
  default = "10.99.0.254"
}
