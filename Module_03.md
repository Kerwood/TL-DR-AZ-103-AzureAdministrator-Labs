# Implement and Manage Storage
### Objectives
After completing this lab, you will be able to:

- Deploy an Azure VM by using an Azure Resource Manager template
- Implement and use Azure Blob Storage
- Implement and use Azure File Storage
- Exercise 0: Prepare the lab environment

---

### Exercise 0: Prepare the lab environment

Make sure the following Resource Providers are enabled on your subscription.
- Microsoft.Network
- Microsoft.Compute
- Microsoft.Storage

Run the below code in the Cloud Shell.
```
# Create a new resource group
New-AzResourceGroup -Name az1000201-RG -l westeurope

# Deploy environment
New-AzResourceGroupDeployment `
  -ResourceGroupName az1000201-RG `
  -TemplateUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_03/Implement_and_Manage_Storage/az-100-02_azuredeploy.json `
  -TemplateParameterUri https://raw.githubusercontent.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator/master/Allfiles/Labfiles/Module_03/Implement_and_Manage_Storage/az-100-02_azuredeploy.parameters.json `
  -AsJob
  ```

---

### Exercise 1: Implement and use Azure Blob Storage

#### Task 1: Create Azure Storage accounts

1. Create a new resource group named `az1000202-RG`, in the same region as the task before.  
Create a Storage account in the newly created resource group, with below properties.
    - Location: Same as resource group in previous task.
    - Account kind: `Storage (general purpose v1)`
    - Replication: `Locally-redundant storage (LRS)`

1. Now create a new resouce group named `az1000203-RG` in another location than in the previous task.  
Create a Storage account in the newly created resource group, with below properties.
    - Location: Different resource group as in previous task.
    - Account kind: `StorageV2 (general purpose v2)`
    - Access tier: `Hot`
    - Replication: `Geo-redundant storage (GRS)`

#### Task 2: Review configuration settings of Azure Storage accounts
Have a look around..

#### Task 3: Manage Azure Storage Blob Service

1. On the first storage account created, create a new container named `az1000202-container` with the Public access level set to Private.  
1. Upload a random file to the container.

#### Task 4: Copy a container and blobs between Azure Storage accounts

Run below code to prepare the storage accounts.
```
# Prepare storage accounts.
$containerName = 'az1000202-container'
$storageAccount1Name = (Get-AzStorageAccount -ResourceGroupName 'az1000202-RG')[0].StorageAccountName
$storageAccount2Name = (Get-AzStorageAccount -ResourceGroupName 'az1000203-RG')[0].StorageAccountName
$storageAccount1Key1 = (Get-AzStorageAccountKey -ResourceGroupName 'az1000202-RG' -StorageAccountName $storageAccount1Name)[0].Value
$storageAccount2Key1 = (Get-AzStorageAccountKey -ResourceGroupName 'az1000203-RG' -StorageAccountName $storageAccount2Name)[0].Value
$context1 = New-AzStorageContext -StorageAccountName $storageAccount1Name -StorageAccountKey $storageAccount1Key1
$context2 = New-AzStorageContext -StorageAccountName $storageAccount2Name -StorageAccountKey $storageAccount2Key1

# Create identical container on second storage account.
New-AzStorageContainer -Name $containerName -Context $context2 -Permission Off

# Generate SAS keys.
$containerToken1 = New-AzStorageContainerSASToken -Context $context1 -ExpiryTime(get-date).AddHours(24) -FullUri -Name $containerName -Permission rwdl
$containerToken2 = New-AzStorageContainerSASToken -Context $context2 -ExpiryTime(get-date).AddHours(24) -FullUri -Name $containerName -Permission rwdl
```

Copy the content of the container between the storage accounts.
```
azcopy cp $containerToken1 $containerToken2 --recursive=true
```

Go to the second storage account and verify the container `az1000202-container` was created and that the random uploaded data was copied.

#### Task 5: Use a Shared Access Signature (SAS) key to access a blob

1. Go to the newly created container `az1000202-container` and copy the URL for the random file you uplaoded. Now open a browser and go to the copied URL to verify that you do not have access.

1. Go back to Azure Portal and generate a SAS token for the random file, with the following properties.
    - Read permissions.
    - A start and expiration date/time.
    - HTTP Allowed.

1. Copy the generated Blob SAS URL and paste it in your browser again to verify that you do now have access to the random file you uploaded.

---

### Exercise 2: Implement and use Azure File Storage

#### Task 1: Create an Azure File Service share

1. On the second storage account you created in the previous exercise (StorageV2), create a File Share with below properties.
    - Name: `az10002share1`
    - Quota: `5GB`

#### Task 2: Map a drive to the Azure File Service share from an Azure VM

1. Navigate to the newly created File Share and get the PowerShell script for connecting a client to the share.

1. Use RDP and connect to the VM `az1000201-vm1`, with below credentials. Once connected use the PowerShell script to mount the File Share to the client.
    - Username: `Student`
    - Password: `Pa55w.rd1234`

1. After mounting the File Share, create a random file on it and validate that it got created on the storage account.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```