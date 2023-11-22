$logFilePath = "C:\Path\To\Your\Log\EnableLocalAdminLog.txt"
$workspaceId = "YourLogAnalyticsWorkspaceId"
$workspaceKey = "YourLogAnalyticsWorkspaceKey"

function LogMessage {
    param(
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFilePath -Value "$timestamp - $message"
    Write-EventLog -LogName Application -Source "EnableLocalAdminScript" -EventId 1001 -EntryType Information -Message $message

    # Send logs to Log Analytics
    $logData = @{
        "Timestamp" = $timestamp
        "Message" = $message
    }
    $jsonLog = $logData | ConvertTo-Json
    $headers = @{
        "Content-Type" = "application/json"
        "Log-Type" = "EnableLocalAdminLog"
        "Authorization" = "SharedKeyLite $workspaceId:$workspaceKey"
    }
    $uri = "https://$workspaceId.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonLog
}

$keyVaultName = "YourKeyVaultName"
$secretName = "LocalAdminPassword"

$secret = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName).SecretValueText

$userName = "Administrator"
$computer = $env:COMPUTERNAME

$existingUser = Get-LocalUser -Name $userName -ErrorAction SilentlyContinue

if ($existingUser -eq $null) {
    $securePassword = ConvertTo-SecureString -String $secret -AsPlainText -Force
    New-LocalUser -Name $userName -Password $securePassword -Description "Local Admin Account" -UserMayNotChangePassword
    Set-AdmPwdAccountPassword -Identity $userName
    Add-LocalGroupMember -Group "Administrators" -Member $userName
    LogMessage "Local Admin account '$userName' created, managed by LAPS, and added to Administrators group on computer '$computer'."
} else {
    $isAdmin = (Get-LocalGroupMember -Group "Administrators" -Member $userName -ErrorAction SilentlyContinue) -ne $null
    if (-not $isAdmin) {
        Enable-LocalUser -Name $userName
        Set-AdmPwdAccountPassword -Identity $userName
        Add-LocalGroupMember -Group "Administrators" -Member $userName
        LogMessage "Local Admin account '$userName' enabled on computer '$computer' and added to Administrators group."
    } else {
        LogMessage "Local Admin account '$userName' already exists, is a member of Administrators group, and is managed by LAPS on computer '$computer'."
    }
}

LogMessage "Script executed successfully."
