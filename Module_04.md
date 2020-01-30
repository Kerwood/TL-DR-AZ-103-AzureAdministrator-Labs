# Configure Azure DNS

### Objectives

After completing this lab, you will be able to:
- Configure Azure DNS for public domains
- Configure Azure DNS for private domains

---

### Exercise 1: Configure Azure DNS for public domains

#### Task 1: Create a public DNS zone
1. Create a new resource group called `az1000401b-RG`.
1. Create a new DNS Zone in above resource group, with a unique, valid DNS domain name in the `.com` namespace.


#### Task 2: Create a DNS record in the public DNS zone
1. Create a new public ip address in the new resource group, with below properties.
    - Name: `az1000401b-pip`
    - Type: Static
    - SKU: Basic
1. Add a new record to the DNS Zone created with below properties.
    - Name: `mylabvmpip`
    - Type: A
    - IP Address: Any IP really. It doesn't really matter.
1. Create another record but this time add it to the Public IP resource that you create earlier.
    - Name: `myazurepip`
    - Type: A
    - Resource: `az1000401b-pip`

#### Task 3: Validate Azure DNS-based name resolution for the public domain

On the public DNS zone you created, note the URL for one of the name servers.
Now verify on your laptop, that the DNS records have been created on the name servers by asking them directly.
```
nslookup mylabvmpip.<custom_DNS_domain> <name_server>
nslookup myazurepip.<custom_DNS_domain> <name_server>
```
or
```
dig @<name_server> mylabvmpip.<custom_DNS_domain>
dig @<name_server> myazurepip.<custom_DNS_domain>
```
Verify that the IP addresses returned match those you identified earlier in this task.

---

### Exercise 2: Configure Azure DNS for private domains

#### Task 1: Provision a multi-virtual network environment

Run below code to create two Azure virtual networks.
```
# Create resource groups
$rg1 = Get-AzResourceGroup -Name 'az1000401b-RG'
$rg2 = New-AzResourceGroup -Name 'az1000402b-RG' -Location $rg1.Location

# Subnet/VNet 1
$subnet1 = New-AzVirtualNetworkSubnetConfig -Name subnet1 -AddressPrefix '10.104.0.0/24'

$vnet1 = New-AzVirtualNetwork -ResourceGroupName $rg2.ResourceGroupName -Location $rg2.Location -Name az1000402b-vnet1 -AddressPrefix 10.104.0.0/16 -Subnet $subnet1

# Subnet/VNet 2
$subnet2 = New-AzVirtualNetworkSubnetConfig -Name subnet1 -AddressPrefix '10.204.0.0/24'

$vnet2 = New-AzVirtualNetwork -ResourceGroupName $rg2.ResourceGroupName -Location $rg2.Location -Name az1000402b-vnet2 -AddressPrefix 10.204.0.0/16 -Subnet $subnet2
```

#### Task 2: Create a private DNS zone

Run below code to create a private DNS zone with the first virtual network supporting registration and the second virtual network supporting resolution.

```
Install-Module -Name Az.PrivateDns -force

$vnet1 = Get-AzVirtualNetwork -Name az1000402b-vnet1
$vnet2 = Get-AzVirtualNetwork -name az1000402b-vnet2

$zone = New-AzPrivateDnsZone -Name adatum.corp -ResourceGroupName $rg2.ResourceGroupName

$vnet1link = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.Name -ResourceGroupName $rg2.ResourceGroupName -Name "vnet1Link" -VirtualNetworkId $vnet1.id -EnableRegistration

$vnet2link = New-AzPrivateDnsVirtualNetworkLink -ZoneName $zone.Name -ResourceGroupName $rg2.ResourceGroupName -Name "vnet2Link" -VirtualNetworkId $vnet2.id
```

Run the following in order to verify that the private DNS zone was successfully created.
```
Get-AzPrivateDnsZone -ResourceGroupName $rg2.ResourceGroupName
```

#### Task 3: Deploy Azure VMs into virtual networks

Deploy below templates.
```
# Deploy template 01
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg2.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_04/Configure_Azure_DNS/az-100-04b_01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_04/Configure_Azure_DNS/az-100-04_azuredeploy.parameters.json `
  -AsJob

  # Deploy template 02
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg2.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_04/Configure_Azure_DNS/az-100-04b_02_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_04/Configure_Azure_DNS/az-100-04_azuredeploy.parameters.json `
  -AsJob
  ```

  Wait for both deployments to complete before you proceed to the next task. You can identify the state of the jobs by running the `Get-Job` cmdlet in the Cloud Shell pane.

#### Task 4: Validate Azure DNS-based name reservation and resolution for the private domain

Use RDP and connect to the newly created VM `az1000402b-vm2`, with below credentials.
    - Username: `Student`
    - Password: `Pa55w.rd1234`

Within the Remote Desktop session to `az1000402b-vm2`, start a PowerShell window and run the following.
```
nslookup az1000402b-vm1.adatum.corp
```

Verify that the name is successfully resolved.

In your local PowerShell session or Cloud Shell session, run the following in order to create an additional DNS record in the private DNS zone.

```
New-AzPrivateDnsRecordSet -ResourceGroupName $rg2.ResourceGroupName -Name www -RecordType A -ZoneName adatum.corp -Ttl 3600 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -IPv4Address "10.104.0.4")
```

Switch again to the Remote Desktop session to `az1000402b-vm2` and run the following from the PowerShell window.

```
nslookup www.adatum.corp
```

Verify that the name is successfully resolved.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```