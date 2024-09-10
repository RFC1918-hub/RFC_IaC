if ((gwmi win32_computersystem).partofdomain -eq $false) {
    Write-Host "Installing Active Directory Domain Services"
    # Installing RSAT tools
    Import-Module ServerManager
    Add-WindowsFeature RSAT-AD-Tools, RSAT-AD-PowerShell, RSAT-AD-AdminCenter

    # Disable password complexity requirements
    secedit /export /cfg C:\secpol.cfg
    (Get-Content C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
    secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
    Remove-Item -force C:\secpol.cfg -confirm:$false

    # Installing Active Directory Domain Services
    $computerName = $env:COMPUTERNAME
    $adminPassword = "vagrant"
    $adminUser = [ADSI] "WinNT://$computerName/Administrator,User"
    $adminUser.SetPassword($adminPassword)

    $securePassword = ConvertTo-SecureString $adminPassword -AsPlainText -Force

    Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
    Import-Module ADDSDeployment
    Install-ADDSForest `
        -SafeModeAdministratorPassword $SecurePassword `
        -CreateDnsDelegation:$false `
        -DatabasePath "C:\Windows\NTDS" `
        -DomainName "Empire.local" `
        -DomainNetbiosName "EMPIRE" `
        -InstallDns:$true `
        -LogPath "C:\Windows\NTDS" `
        -NoRebootOnCompletion:$true `
        -SysvolPath "C:\Windows\SYSVOL" `
        -Force:$true
    
    $dnsServers = "8.8.8.8", "8.8.4.4"
    $adapters = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -And ($_.IPAddress).StartsWith($subnet) }
    if ($adapters) {
        $adapters | ForEach-Object {$_.SetDNSServerSearchOrder($dnsServers)}
    }
}

