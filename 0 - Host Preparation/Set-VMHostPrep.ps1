function Set-VMHostPrep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string[]]$VMHost,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string]$HostName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string]$DomainName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string[]]$SearchDomain,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string[]]$DnsAddress,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)][string[]]$NtpServer
    )
    
    begin {
        $cred = Get-Credential
    }
    
    process {
        foreach ($esxi in $vmhost) {
            if (Connect-VIServer -Server $esxi -Credential $cred) {
                $DnsAddress = $DnsAddress -split ','
                $SearchDomain = $SearchDomain -split ','
                $vmHostNetworkInfo = Get-VmHostNetwork -VMHost $esxi
                Set-VmHostNetwork -Network $vmHostNetworkInfo -HostName $HostName -DomainName $DomainName -SearchDomain $SearchDomain -DnsAddress $DnsAddress

                $NtpServer = $NtpServer -split ','
                Add-VMHostNtpServer -VMHost $esxi -NtpServer $NtpServer
                Get-VMHostService -VMHost $esxi | Where-Object { $_.Key -eq 'ntpd' }  | Start-VMHostService
                Get-VMHostService -VMHost $esxi | Where-Object { $_.Key -eq 'ntpd' }  | Set-VMHostService -Policy On
    
                Get-VMHostService -VMHost $esxi | Where-Object { $_.Key -eq 'TSM-SSH' }  | Start-VMHostService
                Get-VMHostService -VMHost $esxi | Where-Object { $_.Key -eq 'TSM-SSH' }  | Set-VMHostService -Policy On
    
                #Get-AdvancedSetting -Entity (Get-VMHost -Name $esxi) -Name 'Mem.ShareForceSalting' | Set-AdvancedSetting -Value 0 -Confirm:$false
                #Get-AdvancedSetting -Entity (Get-VMHost -Name $esxi) -Name 'UserVars.ToolsRamdisk' | Set-AdvancedSetting -Value 1 -Confirm:$false

                #https://vrandombites.co.uk/powercli/powercli-configure-multiple-esxi-power-policy/
                (Get-View (Get-VMHost -Name $esxi | Get-View).ConfigManager.PowerSystem).ConfigurePowerPolicy(1)

                Disconnect-VIServer -Server $esxi -Confirm:$false
            }
        }
    }
    
    end {
        
    }
}