# Implement Directory Synchronization

### Objectives

After completing this lab, you will be able to:
- Deploy an Azure VM hosting an Active Directory domain controller
- Create and configure an Azure Active Directory tenant
- Synchronize Active Directory forest with an Azure Active Directory tenant

---

### Exercise 1: Deploy an Azure VM hosting an Active Directory domain controller

#### Task 1: Identify an available DNS name for an Azure VM deployment

1. Sign in to https://portal.azure.com/ using an account that has the Owner role in the Azure subscription you intend to use in this lab and is a Global Administrator of the Azure AD tenant associated with that subscription.

1. Next you need to find a unique domain label in the Azure region into which you want to deploy the Azure VM that will host an Active Directory domain controller. Use the following command to find one.
    ```
    Test-AzDnsAvailability -DomainNameLabel <custom-label> -Location '<location>'
    ```

#### Task 2: Deploy an Azure VM hosting an Active Directory domain controller by using an Azure Resource Manager template

1. Go to https://github.com/Azure/azure-quickstart-templates and click the `active-directory-new-domain` directory. At the bottom should be a blue button that says **Deploy to Azure**. Open that link.

1. The link opens the **Template deployment** page at the Azure Portal. Fill in these values.
    - Subscription: *The name of the subscription you are using in this lab*
    - Resource group: *The name of a **new** resource group `az1000501-RG`*
    - Location: *The name of the Azure region you found your domain label*
    - Admin Username: `Student`
    - Admin Password: `Pa55w.rd1234`
    - Domain Name: `adatum.com`
    - Dns Prefix: *The `<custom-label>` you identified in the previous task*
    - VM Size: `Standard_D2s_v3`
    - _artifacts Location: *Accept the default value*
    - _artifacts Location Sas Token: *Leave blank*
    - Location: *Accept the default value*

>Note: This can take some time. Do not wait for the deployment to complete but proceed to the next exercise.

---

### 1. Exercise 2: Create and configure an Azure Active Directory tenant

#### Task 1: Create an Azure Active Directory (AD) tenant

1. Create a new Azure Active Directory with the following settings.
    - Organization name: `AdatumSync`
    - Initial domain name: *A unique name consisting of a combination of letters and digits.*
    - Country or region: *A country near you*

#### Task 2: Add a custom DNS name to the new Azure AD tenant

1. In the Azure portal, set the Directory + subscription filter to the newly created Azure AD tenant.

    >Note: The Directory + subscription filter appears to the left of the notification icon in the toolbar of the Azure portal. You might need to refresh the browser window if the AdatumSync entry does not appear in the Directory + subscription filter list.

1. In the Azure portal, navigate to the AdatumSync - **Custom domain names** blade and identify the primary, default DNS domain name associated with the Azure AD tenant. Note its value - you will need it in the next task.

2. Now add new custom domain named `adatum.com`. On the adatum.com blade, review the information necessary to perform verification of the Azure AD domain name.

You will not be able to complete the validation process because you do not own the adatum.com DNS domain name. This will not prevent you from synchronizing the adatum.com Active Directory domain with the Azure AD tenant. You will use for this purpose the default primary DNS name of the Azure AD tenant (the name ending with the onmicrosoft.com suffix), which you identified earlier in this task. However, keep in mind that, as a result, the DNS domain name of the Active Directory domain and the DNS name of the Azure AD tenant will differ. This means that Adatum users will need to use different names when signing in to the Active Directory domain and when signing in to Azure AD tenant.

#### Task 3: Create an Azure AD user with the Global Administrator role

1. Go to the **Users** blade of the **AdatumSync** AD tenant and create a new user with the following properties.
    - User name: *`syncadmin@<DNS-domain-name>` where `<DNS-domain-name>` represents the default primary DNS domain name you identified in the previous task. Take a note of this user name. You will need it later in this lab.*
    - Name: `syncadmin`
    - Password: *Click Let me create the password and type `Pa55w.rd1234` in the initial password text box.
    - Groups: 0 groups selected
    - Roles: *Click **User** and select **Global administrator***

    >Note: An Azure AD user with the Global Administrator role is required in order to implement Azure AD Connect.

1. Open a new browser windows in Incognito mode and login to the Azure Portal with the `syncadmin` user.
    >Note: You will need to provide the fully qualified name of the syncadmin user account, including the Azure AD tenant DNS domain name. You will also be prompted to change your password.

1. Sign out as syncadmin and close the Incognito browser window.

---

### Exercise 3: Synchronize Active Directory forest with an Azure Active Directory tenant

#### Task 1: Configure Active Directory in preparation for directory synchronization

1. In the Azure portal, set the Directory + subscription filter back to the Azure AD tenant associated with the Azure subscription you used in the first exercise of this lab.

1. Use RDP to connect to the `adVM` Virtual Machine with credentials: `Student:Pa55w.rd1234` and open **Active Directory Administrative Center**.

1. From Active Directory Administrative Center, create a root level organizational unit named ToSync

1. in the organizational unit ToSync, create a new user account with the following settings:
    - Full name: `aduser1`
    - User UPN logon: `aduser1@adatum.com`
    - User SamAccountName logon: `adatum\aduser1`
    - Password: `Pa55w.rd1234`
    - Other password options: `Password never expires`

#### Task 2: Install Azure AD Connect

1. Within the RDP session to adVM, from Server Manager, disable temporarily IE Enhanced Security Configuration.

1. Within the RDP session to adVM, start Internet Explorer and download Azure AD Connect from https://www.microsoft.com/en-us/download/details.aspx?id=47594

1. Start **Microsoft Azure Active Directory Connect** wizard, accept the licensing terms, and, on the **Express Settings** page, select the **Customize** option.

1. On the **Install required components** page, leave all optional configuration options deselected and start the installation.

1. On the User sign-in page, ensure that only the Password Hash Synchronization is enabled.

1. When prompted to connect to Azure AD, authenticate by using the credentials of the `syncadmin` account you created in the previous exercise.

1. When prompted to connect your directories, add the adatum.com forest, choose the option to Create new AD account, and authenticate by using the following credentials:
    - User name: `ADATUM\Student`
    - Password: `Pa55w.rd1234`

1. On the **Azure AD sign-in configuration** page, note the warning stating **Users will not be able to sign-in to Azure AD with on-premises credentials if the UPN suffix does not match a verified domain** and enable the checkbox **Continue without matching all UPN suffixes to verified domain.**

    >Note: As explained earlier, this is expected, since you could not verify the custom Azure AD DNS domain adatum.com.

1. On the **Domain and OU filtering** page, ensure that only the **ToSync** OU is selected.
1. On the **Uniquely identifying your users** page, accept the default settings.
1. On the **Filter users and devices** page, accept the default settings.
1. On the **Optional features** page, accept the default settings.
1. On the **Ready to configure** page, ensure that the **Start the synchronization process when configuration completes** checkbox is selected and continue with the installation process.


#### Task 3: Verify directory synchronization

1. From your local machine, go to the **Users** blade of the **AdatumSync** Azure AD and refresh it. Note that the list of user objects includes the `aduser1` account, with the **Windows Server AD** appearing in the **Source** column.

1. Display the `aduser1` - Profile blade. Note that the Department attribute is not set.

1. Within the RDP session to `adVM`, switch to the **Active Directory Administrative Center**, open the window displaying properties of the `aduser1` user account, and set the value of its **Department** attribute to `Sales`.

1. Within the RDP session to `adVM`, start Windows PowerShell as Administrator and start Azure AD Connect delta synchronization by running the following:

    ```
    Import-Module -Name 'C:\Program Files\Microsoft Azure AD Sync\Bin\ADSync\ADSync.psd1'
    Start-ADSyncSyncCycle -PolicyType Delta
    ```

1. Now refresh the **Users - All users** blade of the AdatumSync Azure AD tenant. Note that the **Department** attribute is now set to `Sales`.

---

### Exercise 4: Remove lab resources

#### Task 1: Delete the Azure AD tenant.

1. Within the RDP session to `adVM`, start Windows PowerShell as Administrator and follow below steps.

1. Install the MsOnline PowerShell module by running the following (when prompted, in the NuGet provider is required to continue dialog box, click Yes):

    ```
    Install-Module MsOnline -Force
    ```
1. Connect to the AdatumSync Azure AD tenant by running the following (when prompted, sign in with the `SyncAdmin` credentials):

    ```
    Connect-MsolService
    ```

1. Disable the Azure AD Connect synchronization by running the following:

    ```
    Set-MsolDirSyncEnabled -EnableDirSync $false -Force
    ```

1. Verify that the operation was successful by running the following:

    ```
    (Get-MSOLCompanyInformation).DirectorySynchronizationEnabled
    ```

1. Open a Incognito window in your browser and login to Azure Portal with the `SyncAdmin` credentials.

1.  Navigate to the **Users - All users** blade of the AdatumSync Azure AD tenant and delete all users with the exception of the `SyncAdmin` account.

    >Note: You might need to wait a few hours before you can complete this step. Although I was able to do it straight away.

1. Navigate to the **AdatumSync - Overview** blade and click **Properties**.

1. On the **Properties** blade of **Azure Active Directory** click **Yes** in the **Access management for Azure resource** section and then click **Save**.

1. Sign out from the Azure portal and sign back in by using the `SyncAdmin` credentials.

1. Navigate to the **AdatumSync - Overview** blade and delete the Azure AD tenant by clicking **Delete directory**.

1. On the **Delete directory ‘AdatumSync’?** blade, click **Delete**.

Boom, you're done!

---

### Clean Up

```
az group list --query "[?starts_with(name,'az1000')].name" --output tsv | xargs -L1 bash -c 'az group delete --name $0 --no-wait --yes'
```