FROM mcr.microsoft.com/powershell

LABEL maintainer="Patrick Kerwood <patrick@kerwood.dk>"

RUN apt update \
  && apt -y install curl \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && curl -sL https://aka.ms/downloadazcopy-v10-linux -o azcopy_linux_amd64_10.tar.gz \
  && tar -zxvf ./azcopy_linux_amd64_10.tar.gz -C /usr/local/bin/ --wildcards azcopy_linux_amd64_10*/azcopy --strip-components=1 \
  && pwsh -Command 'Install-Module -Name Az -AllowClobber -Scope CurrentUser -Confirm:$False -Force'