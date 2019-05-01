variable "prefix" {
  description = "The prefix used for all resources in this example"
  default = "mctf"
}

variable "location" {
  description = "The Azure location where all resources in this example should be created"
  default = "westcentralus"
}

variable "addrSpace" {
  description = "The CIDR block for the VNet to be created."
  default = "10.99.0.0/16"
}