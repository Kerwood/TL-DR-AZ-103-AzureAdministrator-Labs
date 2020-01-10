# TL-DR-AZ-103-AzureAdministrator-Labs
This is a minified version of the offcial AZ-103 Labs from https://microsoftlearning.github.io/AZ-103-MicrosoftAzureAdministrator/  
You can find the original documentation here https://github.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator

## 02 - Deploy and Manage Virtual Machines

### Objectives

After completing this lab, you will be able to:

-  Deploy Azure VMs by using the Azure portal, Azure PowerShell, and Azure Resource Manager templates
-  Configure networking settings of Azure VMs running Windows and Linux operating systems
-  Deploy and configure Azure VM scale sets

---

### Exercise 1: Deploy Azure VMs by using the Azure portal, Azure PowerShell, and Azure Resource Manager templates

#### Task 1: Deploy an Azure VM running `Windows Server 2016 Datacenter` into an availability set by using the Azure portal

Deploy below VM with an availability set, in a new resouce group called `az1000301-RG`.

  - Virtual machine
    - Name: `az1000301-vm0`
    - Image: `[smalldisk] Windows Server 2016 Datacenter`
    - Size: `Standard DS2_v2`
    - Username: `Student`
    - Password: `Pa55w.rd1234`
    - No public inbound ports
    - OS disk type: `Standard HDD`
  - Availability set
    - Name: `az1000301-avset0`
    - Fault domains: 2
    - Update domains: 5
  - Networking
    - VNet address range: `10.103.0.0/16`
    - Subnet name: `subnet0`
    - Subnet address range: `10.103.0.0/24`
  - Monitoring
    - Boot diagnostics: `Off`

*Wait for the deployment to complete before you proceed to the next task. This should take about 5 minutes.*

#### Task 2: Deploy an Azure VM running `Windows Server 2016 Datacenter` into the existing availability set by using Azure PowerShell

Run below commands to setup the prerequisite for the VM.
```
$vmName = 'az1000301-vm1'
$vmSize = 'Standard_DS2_v2'
$resourceGroup = Get-AzResourceGroup -Name 'az1000301-RG'
$location = $resourceGroup.Location

$availabilitySet = Get-AzAvailabilitySet -ResourceGroupName $resourceGroup.ResourceGroupName -Name 'az1000301-avset0'
$vnet = Get-AzVirtualNetwork -Name 'az1000301-RG-vnet' -ResourceGroupName $resourceGroup.ResourceGroupName
$subnetid = (Get-AzVirtualNetworkSubnetConfig -Name 'subnet0' -VirtualNetwork $vnet).Id

$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -Name "$vmName-nsg"
$pip = New-AzPublicIpAddress -Name "$vmName-ip" -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -AllocationMethod Dynamic
$nic = New-AzNetworkInterface -Name "$($vmName)$(Get-Random)" -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -SubnetId $subnetid -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

$adminUsername = 'Student'
$adminPassword = 'Pa55w.rd1234'
$adminCreds = New-Object PSCredential $adminUsername, ($adminPassword | ConvertTo-SecureString -AsPlainText -Force)

$publisherName = 'MicrosoftWindowsServer'
$offerName = 'WindowsServer'
$skuName = '2016-Datacenter'

$osDiskType = (Get-AzDisk -ResourceGroupName $resourceGroup.ResourceGroupName)[0].Sku.Name

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -AvailabilitySetId $availabilitySet.Id
Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $adminCreds
Set-AzVMSourceImage -VM $vmConfig -PublisherName $publisherName -Offer $offerName -Skus $skuName -Version 'latest'
Set-AzVMOSDisk -VM $vmConfig -Name "$($vmName)_OsDisk_1_$(Get-Random)" -StorageAccountType $osDiskType -CreateOption fromImage
Set-AzVMBootDiagnostic -VM $vmConfig -Disable
```

Create the VM.
```
New-AzVM -ResourceGroupName $resourceGroup.ResourceGroupName -Location $location -VM $vmConfig
```


#### Task 3: 
Deploy two Azure VMs running Linux into an availability set by using an Azure Resource Manager template

1. Create a new resource group named `az1000302-RG`
2. Through the GUI deploy the template + parameters files from the link below.

https://github.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/tree/master/Allfiles/Labfiles/Module_02/Deploy_and_Manage_Virtual_Machines

*Wait for the deployment to complete before you proceed to the next task. This should take about 5 minutes.*

---

### Exercise 2: Configure networking settings of Azure VMs running Windows and Linux operating systems

#### Task 1: Configure static private and public IP addresses of Azure VMs

1. On the virtual machine `az1000301-vm0`, change the already assigned public IP address from dynamic to static.
1. On the virtual machine `az1000302-vm0`, change the already assigned private IP to static and set it to 10.103.0.100.

#### Task 2: Connect to an Azure VM running Windows Server 2016 Datacenter via a public IP address

1. Change the inbound port rules on VM `az1000301-vm0` to allow `3389/tcp`.
1. Use RDP to connect to `az1000301-vm0` with credentials: `Student:Pa55w.rd1234`

#### Task 3: Connect to an Azure VM running Linux Ubuntu Server via a private IP address

Because no inbound port rules have been allowed on the `az1000302-vm0` Linux machine, use the Windows machine to connect to `az1000302-vm0` with SSH.

1. Use the RDP session
1. Do a `nslookup az1000302-vm0` to confirm the ip address of the Linux machine.
1. Download putty and connect to `az1000302-vm0` with SSH with credentials: `Student:Pa55w.rd1234`

### Exercise 3: Deploy and configure Azure VM scale sets

#### Task 1: Identify an available DNS name for an Azure VM scale set deployment
Nope.. The GUI will validate the DNS name upon creation.

#### Task 2: Deploy an Azure VM scale set

1. Create a Virtual machine scale set with a Load Balancer, in a new resource group called `az1000303-RG`, with below properties.
    - Name: `az1000303vmss0`
    - Image: `Windows Server 2016 Datacenter`
    - Username: `Student`
    - Password: `Pa55w.rd1234`
    - Instance count: `1`
    - Instance size: `Standard DS2 v2`
    - Public IP address name: `az1000303vmss0-ip`
    - Create a new Virtual Network
      - Name: `az1000303-vnet0`
      - Address range: `10.203.0.0/16`
      - Subnet name: `subnet0`
      - Subnet address range: `10.203.0.0/24`
    - Inbound traffic on `80/tcp` should be allowed. 

*Wait for the deployment to complete before you proceed to the next task. This should take about 5 minutes.*

---

### Task 3: Install IIS on a scale set VM by using DSC extensions

Add the PowerShell Desired State Configuration extension to the newly created Scale Set.  
Upload the file `az-100-03_install_iis_vmss.zip` from below link to the "Configuration Modules or Script" input field.  
https://github.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/tree/master/Allfiles/Labfiles/Module_02/Deploy_and_Manage_Virtual_Machines

Fill in the rest of the input fields.
- Module-qualified Name of Configuration: `az-100-03_install_iis_vmss.ps1\IISInstall`
- Data Collection: disabled
- Version: 2.76
- Auto Upgrade Minor Version: Yes

The extension is setup. Now you just need to upgrade the Scale Set Instances.  
*The update will trigger installtion of the DSC configuration script. Wait for upgrade to complete. This should take about 5 minutes.*

When the installation is complete, find the public IP of the Scale Set and paste in your browser to verify the default IIS home page.

Boom, you're done!

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```
