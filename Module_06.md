# Use Azure Network Watcher for monitoring and troubleshooting network connectivity

### Objectives

After completing this lab, you will be able to:
- Deploy Azure VMs, Azure storage accounts, and Azure SQL Database instances by using Azure Resource Manager templates
- Use Azure Network Watcher to monitor network connectivity

---

### Exercise 1: Prepare infrastructure for Azure Network Watcher-based monitoring

#### Task 1: Deploy Azure VMs, an Azure Storage account, and an Azure SQL Database instance by using Azure Resource Manager templates

Deploy below templates.
```
# Create a new resource group
$rg1 = New-AzResourceGroup -Name az1010301b-RG -l westeurope

# Deploy template 01
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg1.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_06/Network_Watcher/az-101-03b_01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_06/Network_Watcher/az-101-03b_01_azuredeploy.parameters.json `
  -AsJob

# Create a new resource group
$rg2 = New-AzResourceGroup -Name az1010302b-RG -l northeurope

  # Deploy template 02
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg2.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_06/Network_Watcher/az-101-03b_02_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_06/Network_Watcher/az-101-03b_02_azuredeploy.parameters.json `
  -AsJob
  ```

#### Task 2: Enable Azure Network Watcher service

1. Go to the Network Watcher blade, and verify that Network Watcher is enabled in both Azure regions into which you deployed resources in the previous task and, if not, enable it. In above deployment commands, its West and North Europe.

#### Task 3: Establish peering between Azure virtual networks

1. Create a VNet peering from the `az1010301b-vnet1` VNet to the `az1010302b-vnet2` VNet, with the following properties.

    - Name: `az1010301b-vnet1-to-az1010302b-vnet2`
    - Virtual network: `az1010302b-vnet2`
    - Name of peering from az1010302b-vnet2 to az1010301b-vnet1: `az1010302b-vnet2-to-az1010301b-vnet1`

#### Task 4: Establish service endpoints to an Azure Storage account and Azure SQL Database instance

1. On the `az1010301b-vnet1`, create a new Service Endpoint with the following properties.

    - Service: `Microsoft.Storage`
    - Subnets: `subnet0`

1. Repeat the step to create a second Service Endpoint.

    - Service: `Microsoft.Sql`
    - Subnets: `subnet0`

1. Go to the Storage Account of the `az1010301b-RG` resource group. Navigate to the **Firewalls and virtual networks** blade and configure the following settings.

    - Allow access from: `Selected networks`
    - Virtual networks:
        - VIRTUAL NETWORK: `az1010301b-vnet1`
            - SUBNET: `subnet0`

1. Now navigate to the Azure SQL Server blade in the same resource group and configure **Firewalls and virtual networks** with the following settings.

    - Virtual networks:
      - Name: `az1010301b-vnet1`
      - Subscription: *The name of the subscription you are using in this lab*
      - Virtual network: `az1010301b-vnet1`
      - Subnet name: `subnet0/10.203.0.0/24`

---

### Exercise 2: Use Azure Network Watcher to monitor network connectivity

#### Task 1: Test network connectivity to an Azure VM via virtual network peering by using Network Watcher

1. Navigate to **Connection troubleshoot** on the **Network Watcher** blade. Initiate a check with the following settings.

    - Source:
      - Subscription: *The name of the Azure subscription you are using in this lab*
      - Resource group: `az1010301b-RG`
      - Source type: `Virtual machine`
      - Virtual machine: `az1010301b-vm1`
    - Destination: Specify manually
      - URI, FQDN or IPv4: `10.203.16.4`
    - Probe Settings:
      - Protocol: `TCP`
      - Destination port: `3389`


>Note: 10.203.16.4 is the private IP address of the second Azure VM az1010302b-vm1 which you deployed to another Azure region

1. Wait until results of the connectivity check are returned and verify that the status is Reachable. Review the network path and note that the connection was direct, with no intermediate hops in between the VMs.

>Note: If this is the first time you are using Network Watcher, the check can take up to 5 minutes.

#### Task 2: Test network connectivity to an Azure Storage account by using Network Watcher

1. From your shell, run the following command to identify the IP address of the blob service endpoint of the Azure Storage account you provisioned in the previous exercise.

```
[System.Net.Dns]::GetHostAddresses($(Get-AzStorageAccount -ResourceGroupName 'az1010301b-RG')[0].StorageAccountName + '.blob.core.windows.net').IPAddressToString
```

2. On the **Network Watcher** blade initiate a new Connection troubleshoot with the following settings.

    - Source:
      - Subscription: *The name of the Azure subscription you are using in this lab*
      - Resource group: `az1010301b-RG`
      - Source type: `Virtual machine`
      - Virtual machine: `az1010301b-vm1`
    - Destination: Specify manually
        - URI, FQDN or IPv4: *The IP address of the blob service endpoint of the storage account you identified in the previous step of this task*
    - Probe Settings:
        - Protocol: `TCP`
        - Destination port: `443`

1. Wait until results of the connectivity check are returned and verify that the status is Reachable. Review the network path and note that the connection was direct, with no intermediate hops in between the VMs, with minimal latency.

1. Now go to the **Next hop** blade of **Network Watcher and test next hop with the following settings.

    - Subscription: *The name of the Azure subscription you are using in this lab*
    - Resource group: `az1010301b-RG`
    - Virtual machine: `az1010301b-vm1`
    - Network interface: `az1010301b-nic1`
    - Source IP address: `10.203.0.4`
    - Destination IP address: *The IP address of the blob service endpoint of the storage account you identified earlier in this task*

1. Verify that the result identifies the next hop type as `VirtualNetworkServiceEndpoint`.

1. Navigate back to the **Connection troubleshoot** blade and initiate a check with the following settings.

    - Source:
      - Subscription: *The name of the Azure subscription you are using in this lab*
      - Resource group: `az1010302b-RG`
      - Source type: `Virtual machine`
      - Virtual machine: `az1010302b-vm2`
    - Destination: Specify manually
      - URI, FQDN or IPv4: *The IP address of the blob service endpoint of the storage account you identified earlier in this task*
    - Probe Settings:
      - Protocol: `TCP`
      - Destination port: `443`

1. Wait until results of the connectivity check are returned and verify that the status is `Reachable` .

1. Navigate back to the **Next hop** blade and test next hop with the following settings.

    - Subscription: *The name of the Azure subscription you are using in this lab*
    - Resource group: `az1010302b-RG`
    - Virtual machine: `az1010302b-vm2`
    - Network interface: `az1010302b-nic1`
    - Source IP address: `10.203.16.4`
    - Destination IP address: *The IP address of the blob service endpoint of the storage account you identified earlier in this task*

1. Verify that the result identifies the next hop type as Internet

#### Task 3: Test network connectivity to an Azure SQL Database by using Network Watcher

1. Identify the IP address of the Azure SQL Database server you provisioned in the previous exercise with below command.

```
[System.Net.Dns]::GetHostAddresses($(Get-AzSqlServer -ResourceGroupName 'az1010301b-RG')[0].FullyQualifiedDomainName).IPAddressToString
```

2. From the **Network Watcher - Connection troubleshoot** blade, initiate a check with the following settings.

    - Source:
      - Subscription: *The name of the Azure subscription you are using in this lab*
      - Resource group: `az1010301b-RG`
      - Source type: `Virtual machine`
      - Virtual machine: `az1010301b-vm1`
    - Destination: Specify manually
      - URI, FQDN or IPv4: *The IP address of the Azure SQL Database server you identified in the previous step of this task*
    - Probe Settings:
      - Protocol: `TCP`
      - Destination port: `1433`

1. Wait until results of the connectivity check are returned and verify that the status is Reachable. Review the network path and note that the connection was direct, with no intermediate hops in between the VMs, with low latency.

>Note: The connection takes place over the service endpoint you created in the previous exercise. To verify this, you will use the Next hop tool of Network Watcher.

4. Navigate back to the **Next hop** blade and test next hop with the following settings.

    - Subscription: *The name of the Azure subscription you are using in this lab*
    - Resource group: `az1010301b-RG`
    - Virtual machine: `az1010301b-vm1`
    - Network interface: `az1010301b-nic1`
    - Source IP address: `10.203.0.4`
    - Destination IP address: *The IP address of the Azure SQL Database server you identified earlier in this task*

1. Verify that the result identifies the next hop type as VirtualNetworkServiceEndpoint

1. Navigate back to the **Connection troubleshoot** blade and initiate a check with the following settings.

    - Source:
      - Subscription: *The name of the Azure subscription you are using in this lab*
      - Resource group: `az1010302b-RG`
      - Source type: `Virtual machine`
      - Virtual machine: `az1010302b-vm2`
    - Destination: Specify manually
      - URI, FQDN or IPv4: *The IP address of the Azure SQL Database server you identified earlier in this task*
    - Probe Settings:
      - Protocol: `TCP`
      - Destination port: `1433`

1. Wait until results of the connectivity check are returned and verify that the status is Reachable.

>Note: The connection is successful, however it is established over Internet. To verify this, you will use again the Next hop tool of Network Watcher.

8. Navigate back to the **Next hop** blade and test next hop with the following settings.

    - Subscription: *The name of the Azure subscription you are using in this lab*
    - Resource group: `az1010302b-RG`
    - Virtual machine: `az1010302b-vm2`
    - Network interface: `az1010302b-nic1`
    - Source IP address: `10.203.16.4`
    - Destination IP address: *The IP address of the Azure SQL Database server you identified earlier in this task*

1. Verify that the result identifies the next hop type as Internet


Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```