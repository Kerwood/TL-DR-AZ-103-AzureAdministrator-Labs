# VNet Peering and Service Chaining

### Objectives

After completing this lab, you will be able to:
- Create Azure virtual networks and deploy Azure VM by using Azure Resource Manager templates.
- Configure VNet peering.
- Implement custom routing
- Validate service chaining

---

### Exercise 0: Prepare the Azure environment

#### Task 1: Create the virtual networks hosting two Azure VMs by using an Azure Resource Manager template

Deploy below templates.
```
# Create a new resource group
$rg1 = New-AzResourceGroup -Name az1000401-RG -l westeurope

# Deploy template 01
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg1.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_05/VNet_Peering_and_Service_Chaining/az-100-04_01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_05/VNet_Peering_and_Service_Chaining/az-100-04_azuredeploy.parameters.json `
  -AsJob

# Create a new resource group
$rg2 = New-AzResourceGroup -Name az1000402-RG -l westeurope

  # Deploy template 02
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg2.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_05/VNet_Peering_and_Service_Chaining/az-100-04_02_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_05/VNet_Peering_and_Service_Chaining/az-100-04_azuredeploy.parameters.json `
  -AsJob
  ```

  Wait for both deployments to complete before you proceed to the next task. You can identify the state of the jobs by running the `Get-Job` cmdlet in the Cloud Shell pane.

---

### Exercise 1: Configure VNet peering

#### Task 1: Configure VNet peering for the first virtual network

Create a VNet peering from the `az1000401-vnet1` VNet to the `az1000402-vnet2`VNet, with the following properties.
- Name: `az1000401-vnet1-to-az1000402-vnet2`
- Virtual network: `az1000402-vnet2`
- Name of peering from az1000402-vnet2 to az1000401-vnet1: `az1000402-vnet2-to-az1000401-vnet1`

---

### Exercise 2: Implement custom routing

#### Task 1: Enable IP forwarding for a network interface of an Azure VM

On the virtual machine `az1000401-vm2`, enable IP forwarding on the Network Interface: `az1000401-nic2`.

Note: The Azure VM az1000401-vm2, which network interface you configured in this task, will function as a router, facilitating service chaining between the two virtual networks.

#### Task 2: Configure user defined routing

1. Create a new Route table with the following properties.
    - Name: `az1000402-rt1`
    - Resource group: `az1000402-RG`
    - Virtual network gateway route propagation: `Disabled`

2. Add a new route to the route table with the following properties.
    - Route name: `custom-route-to-az1000401-vnet1`
    - Address prefix: `10.104.0.0/16`
    - Next hop type: `Virtual appliance`
    - Next hop address: `10.104.1.4`

3. Now associate the created route table with `subnet0` of `az1000402-vnet2`.

#### Task 3: Configure routing in an Azure VM running Windows Server 2016

1. Use RDP to connect to `az1000401-vm2` with credentials: `Student:Pa55w.rd1234`.

1. Within the Remote Desktop session to `az1000401-vm2`, from **Server Manager**, select **Manage** use the **Add Roles and Features Wizard**.

1. Click **Next** twice, ensure `az1000401-vm2` is selected and click **Next**, select the **Remote Access** server role then click **Next** three times, Select the **Routing** role service, select **Add Features** and all required features. Select **Next** three times, click **Install**. Click **Close** when the installation is complete.

>Note: If you receive an error message "*There may be a version mismatch between this computer and the destination server or VHD*" once you select the **Remote Access** checkbox on the **Server Roles** page of the **Add Roles and Features Wizard**, clear the checkbox, click **Next**, click **Previous** and select the **Remote Access** checkbox again.

1. Within the Remote Desktop session to `az1000401-vm2`, from Server Manager, select **Tools** start the **Routing and Remote Access** console.

1. In the **Routing and Remote Access** console, right click on the server name and select **Configure and Enable Routing and Remote Access**, Select **Next** use the **Custom configuration** then **Next**, enable **LAN routing** then **Next**, click **Finish** and the click **Start Service**.

1. Within the Remote Desktop session to `az1000401-vm2`, start the **Windows Firewall with Advanced Security** console and enable **File and Printer Sharing (Echo Request - ICMPv4-In)** inbound rule for all profiles.

>After completing this exercise, you have implemented custom routing between peered Azure virtual networks.

---

### Exercise 3: Validating service chaining

#### Task 1: Configure Windows Firewall with Advanced Security on the target Azure VM

1. Use RDP to connect to `az1000401-vm1` with credentials: `Student:Pa55w.rd1234`.

1. Within the Remote Desktop session to `az1000401-vm1`, open the **Windows Firewall with Advanced Security** console and enable **File and Printer Sharing (Echo Request - ICMPv4-In)** inbound rule for all profiles.

#### Task 2: Test service chaining between peered virtual networks

1. Use RDP to connect to `az1-1000402-vm3` with credentials: `Student:Pa55w.rd1234`.

1. Run below PS command to verify that the path was indeed routed over `10.104.1.4`, which is `az1000401-vm1`.
```
Test-NetConnection -ComputerName 10.104.0.4 -TraceRoute
```

>Note: Without custom routing in place, the traffic would flow directly between the two Azure VMs. Result: After you completed this exercise, you have validated service chaining between peered Azure virtual networks.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```