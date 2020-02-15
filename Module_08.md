# Load Balancer and Traffic Manager

### Objectives

After completing this lab, you will be able to:
- Deploy Azure VMs by using Azure Resource Manager templates
- Implement Azure Load Balancing
- Implement Azure Traffic Manager load balancing

---

### Exercise 0: Deploy Azure VMs

#### Task 1: Deploy management Azure VMs running Windows Server 2016 Datacenter with the Web Server (IIS) role installed


Deploy below templates.
```
# Create a new resource group
$rg1 = New-AzResourceGroup -Name az1010301-RG -l westeurope

# Deploy template 01
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg1.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_08/Load_Balancer_and_Traffic_Manager/az-101-03_01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_08/Load_Balancer_and_Traffic_Manager/az-101-03_01_1_azuredeploy.parameters.json `
  -AsJob

# Create a new resource group
$rg2 = New-AzResourceGroup -Name az1010302-RG -l northeurope

  # Deploy template 02
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg2.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_08/Load_Balancer_and_Traffic_Manager/az-101-03_01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_08/Load_Balancer_and_Traffic_Manager/az-101-03_01_2_azuredeploy.parameters.json `
  -AsJob
  ```

>Note: The templates is deployed in two different regions.

  ---

### Exercise 1: Implement Azure Load Balancing

#### Task 1: Implement Azure load balancing rules in the first region

>Note: Before you start this task, ensure that the template deployment you started in the first task of the previous exercise has completed.

1. Create a new Load Balancer with the following settings.
    - Subscription: *The name of the subscription you are using in this lab*
    - Resource group: `az1010301-RG`
    - Name: `az1010301w-lb`
    - Region: *The name of the Azure region in which you deployed Azure VMs in the first task of the previous exercise. In this case its West Europe*
    - Type: `Public`
    - SKU: `Basic`
    - Public IP address: *A new public IP address named `az1010301w-lb-pip`*
    - Assignment: `Dynamic`
    - Add a public IPv6 address: `No`

1. Go to the **Backend Pools** of the newly created Load Balancer and create a new pool, with the following settings.
    - Name: `az1010301w-bepool`
    - Virtual network: `az1010301-vnet`
    - IP version: `IPv4`
    - Associated to: `Virtual machine`
    - Virtual machine: `az1010301w-vm0`
    - Network IP configuration: `az1010301w-nic0/ipconfig1 (10.101.31.4)`
    - Virtual machine: `az1010301w-vm1`
    - Network IP configuration: `az1010301w-nic1/ipconfig1 (10.101.31.5)`

    >Note: It is possible that the IP addresses of the Azure VMs are assigned in the reverse order.

    >Note: Wait for the operation to complete. This should take less than a minute.

1. Now go to the **Health probes** blade of the Load Balancer and create a new health probe with the following settings.
    - Name: `az1010301w-healthprobe`
    - Protocol: `TCP`
    - Port: `80`
    - Interval: `5 seconds`
    - Unhealthy threshold: `2 consecutive failures`

    >Note: Wait for the operation to complete. This should take less than a minute.

1. Now go to the **Load balancing rules** blade of the Load Balancer and create a new rule with the following settings.
    - Name: `az1010301w-lbrule01`
    - IP Version: `IPv4`
    - Frontend IP address: `LoadBalancerFrontEnd`
    - Protocol: `TCP`
    - Port: `80`
    - Backend port: `80`
    - Backend pool: `az1010301w-bepool (2 virtual machines)`
    - Health probe: `az1010301w-healthprobe (TCP:80)`
    - Session persistence: `None`
    - Idle timeout (minutes): `4`
    - Floating IP (direct server return): `Disabled`

#### Task 2: Implement Azure load balancing rules in the second region

1. Do the same in the other region.
    - Load Balancer
        -  Subscription: *The name of the subscription you are using in this lab*
        -  Resource group: `az1010302-RG`
        -  Name: `az1010302w-lb`
        -  Region: *The name of the Azure region in which you deployed Azure VMs in the second region. In this case, North Europe.*
        -  Type: `Public`
        -  SKU: `Basic`
        -  Public IP address: *A new public IP address named `az1010302w-lb-pip`*
        -  Assignment: `Dynamic`
        -  Add a public IPv6 address: `No`
    - Backend Pool
        - Name: `az1010302w-bepool`
        - Virtual network: `az1010302-vnet`
        - IP version: `IPv4`
        - Associated to: `Virtual machine`
        - Virtual machine: `az1010302w-vm0`
        - Network IP configuration: `az1010302w-nic0/ipconfig1 (10.101.32.4)`
        - Virtual machine: `az1010302w-vm1`
        - Network IP configuration: `az1010302w-nic1/ipconfig1 (10.101.32.5)`
    - Health probe
        - Name: `az1010302w-healthprobe`
        - Protocol: `TCP`
        - Port: `80`
        - Interval: `5 seconds`
        - Unhealthy threshold: `2 consecutive failures`
    - Load Balancing Rule
        - Name: `az1010302w-lbrule01`
        - IP Version: `IPv4`
        - Frontend IP address: `LoadBalancerFrontEnd`
        - Protocol: `TCP`
        - Port: `80`
        - Backend port: `80`
        - Backend pool: `az1010302w-bepool (2 virtual machines)`
        - Health probe: `az1010302w-healthprobe (TCP:80)`
        - Session persistence: `None`
        - Idle timeout (minutes): `4`
        - Floating IP (direct server return): `Disabled`

#### Task 3: Implement Azure NAT rules in the first region

1. Go to the **Inbound NAT rules** blade of the `az1010301w-lb` Load Balancer and createa new NAT rule with the following settings.
    - Name: `az1010301w-vm0-RDP`
    - Frontend IP address: `LoadBalancerFrontEnd`
    - IP Version: `IPv4`
    - Service: `Custom`
    - Protocol: `TCP`
    - Port: `33890`
    - Target virtual machine: `az1010301w-vm0`
    - Network IP configuration: `ipconfig1 (10.101.31.4) or ipconfig1 (10.101.31.5)`
    - Port mapping: `Custom`
    - Floating IP (direct server return): `Disabled`
    - Target port: `3389`

1. Create another NAT rule.
    - Name: `az1010301w-vm1-RDP`
    - Frontend IP address: `LoadBalancerFrontEnd`
    - IP Version: `IPv4`
    - Service: `Custom`
    - Protocol: `TCP`
    - Port: `33891`
    - Target virtual machine: `az1010301w-vm1`
    - Network IP configuration: `ipconfig1 (10.101.31.4) or ipconfig1 (10.101.31.5)`
    - Port mapping: `Custom`
    - Floating IP (direct server return): `Disabled`
    - Target port: `3389`

#### Task 4: Implement Azure NAT rules in the second region

1. Do the same for the second Load Balancer `az1010302w-lb`.
    - NAT Rule 1
        - Name: `az1010302w-vm0-RDP`
        - Frontend IP address: `LoadBalancedFrontEnd`
        - IP Version: `IPv4`
        - Service: `Custom`
        - Protocol: `TCP`
        - Port: `33890`
        - Target virtual machine: `az1010302w-vm0`
        - Network IP configuration: `ipconfig1 (10.101.32.4) or ipconfig1 (10.101.32.5)`
        - Port mapping: `Custom`
        - Floating IP (direct server return): `Disabled`
        - Target port: `3389`
    - NAT Rule 2
        - Name: `az1010302w-vm1-RDP`
        - Frontend IP address: `LoadBalancedFrontEnd`
        - IP Version: `IPv4`
        - Service: `Custom`
        - Protocol: `TCP`
        - Port: `33891`
        - Target virtual machine: `az1010302w-vm1`
        - Network IP configuration: `ipconfig1 (10.101.32.4) or ipconfig1 (10.101.32.5)`
        - Port mapping: `Custom`
        - Floating IP (direct server return): `Disabled`
        - Target port: `3389`

#### Task 5: Verify Azure load balancing and NAT rules.

1. Get the Public IP for both the Load Balancers.

1. Verify both IP's by browsing to them from your browser. Each IP should show the default IIS site.

1. From your local machine, connect with RDP to the public IP of `az1010301w-lb` and port `33890`. This will initiate a Remote Desktop session to the `az1010301w-vm0` Azure VM by using the `az1010301w-vm0-RDP` NAT rule you created in the previous task. Use the credentials `Student:Pa55w.rd1234` for login.

1. Once connected, verify that the hostname is `az1010301w-vm0`.

1. Repeat the above steps for the other Load Balancer/region.

---

### Exercise 2: Implement Azure Traffic Manager load balancing

#### Task 1: Assign DNS names to public IP addresses of Azure load balancers

This task is necessary because each Traffic Manager endpoint must have a DNS name assigned.

1. On the `az1010301w-lb-pip` public IP, configure a unique DNS name label.

1. Do the same for the other region, `az1010302w-lb-pip`.

#### Task 2: Implement Azure Traffic Manager load balancing

1. Go to **Traffic Manager profile** and create a new **Traffic Manager profile** with the following settings.
    - Name: *A globally unique name in the trafficmanager.net DNS namespace*
    - Routing method: `Weighted`
    - Subscription: *The name of the subscription you are using in this lab*
    - Resource group: *The name of a **new** resource group: `az1010303-RG`*
    - Location: *Either of the Azure regions you used earlier in this lab*

1. From the newly created Traffic Manager profile, create a two Endpoints with the following settings.
    - Endpoint 1
        - Type: `Azure endpoint`
        - Name: `az1010301w-lb-pip`
        - Target resource type: `Public IP address`
        - Target resource: `az1010301w-lb-pip`
        - Weight: `100`
        - Custom Header settings: *leave blank*
        - Add as disabled: *leave blank*
    - Endpoint 2
        - Type: `Azure endpoint`
        - Name: `az1010302w-lb-pip`
        - Target resource type: `Public IP address`
        - Target resource: `az1010302w-lb-pip`
        - Weight: `100`
        - Custom Header settings: *leave blank*
        - Add as disabled: *leave blank*

    On the Endpoints blade, examine the entries in the **Monitoring Status** column for both endpoints. Wait until both are listed as **Online** before you proceed to the next task.

#### Task 3: Verify Azure Traffic Manager load balancing

1. Get the DNS name of the Traffic Manager you created.

1. Verify the DNS name on your local machine. This should match the DNS name of the of the Traffic Manager profile endpoints you created in the previous task.

    ```
    nslookup <TM_DNS_name>
    ```
    or

    ```
    dig <TM_DNS_name>
    ```

1. Wait for at least 60 seconds and run the same command again. This time, the entry should match the DNS name of the other Traffic Manager profile endpoint you created in the previous task.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az101030')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```