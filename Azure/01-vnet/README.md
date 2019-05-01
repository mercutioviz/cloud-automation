# Azure automation
# test 01 - VNet
	- Create resource group
	- Create single VNet
	- Create 3 subnets:
		- fwsubnet
		- websubnet
		- appsubnet
	- Create storage account
	- Create static public IP
		- PIPs for FW ELB (primary, secondary)
		- PIPs for WAF1, WAF2
	- Create Master ELB
		- Front-end primary PIP
		- Front-end secondary PIP
		- Health probe TCP port 65500
		