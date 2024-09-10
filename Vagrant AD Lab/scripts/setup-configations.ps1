# -*- coding: utf-8 -*-

### Set Timezone to UTC
Set-TimeZone -Id "UTC"

### PowerShell profile for Windows
# Save content to C:\Windows\System32\WindowsPowerShell\v1.0\Profile.ps1

$PSProfileContent = @'
$ESC = [char]27

function prompt {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $location = Get-Location

    return "$ESC[32m[$timestamp] PS($ESC[94m$env:UserName@$env:COMPUTERNAME$ESC[32m)-[$ESC[0m$location$ESC[32m]$ESC[94m> $ESC[0m"
}

$ProgressPreference = 'SilentlyContinue'
'@
$PSProfileContent | Out-File -FilePath 'C:\Windows\System32\WindowsPowerShell\v1.0\Profile.ps1' -Encoding UTF8
###

### Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
###

### Configure auditing policies
# Enable auditing categories
#auditpol /set /category:* /success:enable /failure:enable

# Enable logging for PowerShell scripts
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

if (!(Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
}

Set-ItemProperty -Path $registryPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWORD

# Increase the size of Security log
wevtutil set-log Security /maxsize:1073741824

# Enable Command Line Process Auditing
$auditPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit"

if (!(Test-Path $auditPath)) {
    New-Item -Path $auditPath -Force | Out-Null
}

New-ItemProperty -Path $auditPath -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -PropertyType DWORD -Force
###

### Install Sysmon and configure it
# Download Sysmon
$url = "https://download.sysinternals.com/files/Sysmon.zip"
$output = "C:\Sysmon.zip"

Invoke-WebRequest -Uri $url -OutFile $output
# Unzip Sysmon
Expand-Archive -Path $output -DestinationPath "C:\Sysmon"
# Download Sysmon config
$url = "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml"
$output = "C:\Sysmon\sysmonconfig-export.xml"
Invoke-WebRequest -Uri $url -OutFile $output

# Configure Sysmon
& "C:\Sysmon\sysmon64.exe" -accepteula -i "C:\Sysmon\sysmonconfig-export.xml"
### 

### Install Splunk Universal Forwarder
# Get Splunk Universal Forwarder
$url = "https://www.splunk.com/en_us/download/universal-forwarder.html" 
$response = Invoke-WebRequest -Uri $url -UseBasicParsing
$response.content -match 'data-link="(https:\/\/download\.splunk\.com\/products\/universalforwarder\/releases\/.*\/windows\/splunkforwarder-.*-x64-release\.msi)"'
$download_url = $matches[1]

# Download Splunk Universal Forwarder
$output = "C:\SplunkUniversalForwarder.msi"
Invoke-WebRequest -Uri $download_url -OutFile $output
# Install Splunk Universal Forwarder
# Define variables for Splunk server IP and admin password
$splunkAdminPassword = "changeme!"

# Command to install Splunk Universal Forwarder with desired settings
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\SplunkUniversalForwarder.msi", `
    "RECEIVING_INDEXER=192.168.56.100:9997", `
    "WINEVENTLOG_SEC_ENABLE=0", `
    "WINEVENTLOG_SYS_ENABLE=0", `
    "WINEVENTLOG_APP_ENABLE=0", `
    "AGREETOLICENSE=Yes", `
    "SERVICESTARTTYPE=AUTO", `
    "LAUNCHSPLUNK=1", `
    "SPLUNKPASSWORD=$splunkAdminPassword", `
    "/quiet" -NoNewWindow -Wait

# Install Splunk Add-on
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" install app 'C:\vagrant\tools\splunk_forwarder\Splunk Add-on for Microsoft Windows.tgz' -auth admin:changeme!

& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" install app 'C:\vagrant\tools\splunk_forwarder\Splunk Add-on for Sysmon.tgz' -auth admin:changeme!

# Configure Splunk Universal Forwarder
function Copy-ConfigFile {
    param (
        [string]$sourceFile,
        [string]$destinationDir
    )
    
    $destinationFile = "$destinationDir\inputs.conf"
    
    if (-not (Test-Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force
    }

    Copy-Item -Path $sourceFile -Destination $destinationFile -Force
    Write-Host "File copied to $destinationFile"
}

# Copy the TA_windows_inputs.conf file
Copy-ConfigFile "C:\vagrant\tools\splunk_forwarder\inputs\TA_windows_inputs.conf" "C:\Program Files\SplunkUniversalForwarder\etc\apps\Splunk_TA_windows\local"

# Copy the TA_microsoft_sysmon_inputs.conf file
Copy-ConfigFile "C:\vagrant\tools\splunk_forwarder\inputs\TA_microsoft_sysmon_inputs.conf" "C:\Program Files\SplunkUniversalForwarder\etc\apps\Splunk_TA_microsoft_sysmon\local"

# Restart Splunk Universal Forwarder
& "C:\Program Files\SplunkUniversalForwarder\bin\splunk.exe" restart
###


