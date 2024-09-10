param ([String] $dnsServers)

if ((gwmi win32_computersystem).partofdomain -eq $false) {
    Write-Host "Attempting to join domain"
    Write-Host "DNS Servers: $dnsServers"

    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
    $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($dnsServers)}

    # Add dns server to hosts file
    $hostsFile = "$env:windir\System32\drivers\etc\hosts"
    $hostsContent = Get-Content $hostsFile
    $hostsContent += "$dnsServers empire.local dc.empire.local"
    $hostsContent | Set-Content $hostsFile

    $domain = "empire.local"
    $username = "empire.local\vagrant"
    $password = "vagrant"
    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $securePassword)

    Add-Computer -DomainName $domain -Credential $credential -PassThru

    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name AutoAdminLogon -Value 1
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultUserName -Value "vagrant"
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -Name DefaultPassword -Value "vagrant"
}