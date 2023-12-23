# Set TLS protocol version to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install PowerShellGet module
Install-Module -Name PowerShellGet -Force -AllowClobber -Scope CurrentUser -Confirm:$false

# Optionally, update PowerShellGet to the latest version
Update-Module -Name PowerShellGet -Force -AllowClobber -Confirm:$false
