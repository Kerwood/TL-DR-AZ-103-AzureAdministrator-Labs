# Implement Azure Site Recovery between Azure regions

### Objectives

After completing this lab, you will be able to:
- Implement Azure Site Recovery Vault
- Configure replication of Azure VMs between Azure regions by using Azure Site Recovery

---

### Exercise 1: Implement prerequisites for migration of Azure VMs by using Azure Site Recovery

#### Task 1: Deploy an Azure VM to be migrated by using an Azure Resource Manager template


Deploy below templates.
```
# Create a new resource group
$rg1 = New-AzResourceGroup -Name az1010101-RG -l westeurope

# Deploy template
New-AzResourceGroupDeployment `
  -ResourceGroupName $rg1.ResourceGroupName `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_07/Azure_Site_Recovery_Between_Regions/az-101-01_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_07/Azure_Site_Recovery_Between_Regions/az-101-01_azuredeploy.parameters.json `
  -AsJob
  ```

>Note: Do not wait for the deployment to complete but proceed to the next task. You will use the virtual machine `az1010101-vm` in the second exercise of this lab.

#### Task 2: Implement an Azure Site Recovery vault

Search the Market Place for **Backup and Site Recovery** and create a **Recovery Services vault**.

- Subscription: *The same Azure subscription you used in the previous task of this exercise*
- Resource group: The name of a **new** resource group `az1010102-RG`
- Vault name: `vaultaz1010102`
- Region: *The name of an Azure region that is available in your subscription and which is different from the region you deployed the Azure VM in the previous task of this exercise.*

>Note: Wait for the provisioning to complete. This should take about a minute.

Navigate to the newly created vault `vaultaz1010102`. In the **Security Settings** under **Properties**. disable Soft Delete.

---

### Exercise 2: Migrate an Azure VM between Azure regions by using Azure Site Recovery

#### Task 1: Configure Azure VM replication

1. Replicate the vault `vaultaz1010102` with the following settings.

    - Source
        - Source: `Azure`
        - Source location: *The same Azure region into which you deployed your Template in the previous exercise of this lab*
        - Azure virtual machine deployment model: `Resource Manager`
        - Source subscription: *The same Azure subscription you used in the previous exercise of this lab*
        - Source resource group: `az1010101-RG`

    - Virtual machines
        - Virtual machines: `az1010101-vm`

    - Settings
        - Target location: *The name of an Azure region that is available in your subscription and which is different from the region you deployed your Template in, in the previous task. If possible, use the same Azure region into which you deployed the Azure Site Recovery vault.*
        - Target resource group: `(new) az1010101-RG-asr`
        - Target virtual network: `(new) az1010101-vnet-asr`
        - Cache storage account: *Accept the default setting*
        - Replica managed disks: `(new) 1 premium disk(s), 0 standard disk(s)`
        - Target availability sets: `Not Applicable`
        - Replication policy
            - Name: `12-hour-retention-policy`
            - Recovery point retention: `12 Hours`
            - App consistent snapshot frequency: `6 Hours`

    When its done validating, enable the replication.

#### Task 2: Review Azure VM replication settings

1. Navigate to the **Replicated items** of `vaultaz1010102`

    On the **Replicated items** blade, ensure that there is an entry representing the `az1010101-vm` Azure VM and verify that its **REPLICATION HEALTH** is **Healthy** and that its **STATUS** is **Enabling protection**.


    From the `vaultaz1010102` - Replicated items blade, display the replicated item blade of the `az1010101-vm` Azure VM.

    On the `az1010101-vm` replicated item blade, review the Health and status, Failover readiness, Latest recovery points, and Infrastructure view sections. Note the Failover and Test Failover toolbar icons.

>Note: The remaining steps of this task are optional.

If time permits, wait until the replication status changes to 100% synchronized. This might take additional 90 minutes.

1. Examine the values of RPO, as well as Crash-consistent and App-consistent recovery points.

2. Perform a test failover to the `az1010101-vnet-asr` virtual network.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az10101')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```
>Note: If you encounter an error similar to “…cannot perform delete operation because following scope(s) are locked…” then you need to run the following steps **in bash** to remove the lock on the resource that prevents its deletion:

```
lockedresource=$(az resource list --resource-group az1010101-RG-asr --resource-type Microsoft.Compute/disks --query "[?starts_with(name,'az10101')].name" --output tsv)
az disk revoke-access -n $lockedresource --resource-group az1010101-RG-asr
lockid=$(az lock show --name ASR-Lock --resource-group az1010101-RG-asr --resource-type Microsoft.Compute/disks --resource-name $lockedresource --output tsv --query id)
az lock delete --ids $lockid
az group list --query "[?starts_with(name,'az10101')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```