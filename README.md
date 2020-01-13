# [TL;DR] AZ-103-AzureAdministrator-Labs
This is a minified version, without a step by step guide, of the offcial AZ-103 Labs from https://microsoftlearning.github.io/AZ-103-MicrosoftAzureAdministrator/

You can find the original documentation here https://github.com/MicrosoftLearning/AZ-103-MicrosoftAzureAdministrator

In this repository you will find a Dockerfile to create a image with PowerShell for Linux. It is sourced from the official `mcr.microsoft.com/powershell` image but also adds the following.
- Azure PowerShell module
- AzCopy
- Azure CLI

Build the image.
```
docker build -t azure-powerhell .
```

The build output will look a little fucked when it installs the Azure PowerShell module, its totally normal.

Now run the image. Use a volume for the root home directory for persistent logins in Azure CLI and Azure PowerShell module.
```
docker run -it --rm -v powershell:/root azure-powershell
```

## PowerShell Module
Run below command for Azure PowerShell module and follow instructions.
```
Connect-AzAccount
```

## Azure CLI
Run below command for Azure CLI an follow instructions.
```
az login
```

Run below command to configure the CLI, eg. set default output format to table.
```
az configure
```

## Alias
Create an alias in your `~/.bashrc` file to create a docker transparent command for your Azure PowerShell.
```
alias azure-ps='docker run -it --rm -v powershell:/root azure-powershell'
```

Source `~/.bashrc` file.
```
source ~/.bashrc
```

And run the command.
```
$ ~ azure-ps
PowerShell 6.2.3
Copyright (c) Microsoft Corporation. All rights reserved.

https://aka.ms/pscore6-docs
Type 'help' to get help.

PS /> 
```