
# Disable Windows Firewall for all profiles
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

# Verify the firewall is disabled
$firewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled

# Display the current status
Write-Host "Windows Firewall Status:"
$firewallStatus | Format-Table -AutoSize

Write-Host "Windows Firewall has been disabled for all profiles."