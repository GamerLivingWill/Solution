Function Set-ServerDistributionPoint{
[cmdletbinding()]
Param(

    [parameter()][string]$NoSMSOnDriveExclude,
    [parameter()][string[]]$ComputerName

)

    ForEach($Comp in $ComputerName){

        $Drives = (Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Comp) | Where-Object -FilterScript {$PSItem.DriveType -eq 3 -and $PSItem.DeviceID -notlike $NoSMSOnDriveExclude}

        ForEach($Drive in $Drives){
            Invoke-Command -ComputerName $Comp -ScriptBlock {
                $Drive = $using:Drive
                Write-Verbose ("Passing external variable " + $using:Drive)
                Try{Get-Item -Path ($Drive.DeviceID + '\NO_SMS_ON_DRIVE.sms') -ErrorAction Stop
                }
                Catch [System.Exception]{

                    Write-Verbose ("File does not exist on drive." + $Drive.DeviceID)
                    Write-Verbose ("Creating NO_SMS_ON_DRIVE.sms file.")
                    New-Item -Path ($Drive.DeviceID + '\') -Name 'NO_SMS_ON_DRIVE.sms' -ItemType File
    
                }
            }
            

        }

        $CMBasicInboundRulesTCP = @{

            DisplayName = 'SCCM Basic Inbound IP Rules (TCP)'
            Enabled = 'True'
            Direction = 'Inbound'
            Action = 'Allow'
            LocalPort = '80','443','1723','8530','8531','445','135','5985','5986'
            Protocol = 'TCP'
            Profile = 'Domain'

        }

        $CMBasicOutboundRulesTCP = @{

            DisplayName = 'SCCM Basic Outbound IP Rules (TCP)'
            Enabled = 'True'
            Direction = 'Outbound'
            Action = 'Allow'
            LocalPort = '80','443','1723','8530','8531','445','135','5985','5986'
            Protocol = 'TCP'
            Profile = 'Domain'

        }

        $CMBasicInboundRulesUDP = @{

            DisplayName = 'SCCM Basic Inbound IP Rules (UDP)'
            Enabled = 'True'
            Direction = 'Inbound'
            Action = 'Allow'
            LocalPort = '135'
            Protocol = 'UDP'
            Profile = 'Domain'

        }

        $CMBasicOutboundRulesUDP = @{

            DisplayName = 'SCCM Basic Outbound IP Rules (UDP)'
            Enabled = 'True'
            Direction = 'Inbound'
            Action = 'Allow'
            LocalPort = '135'
            Protocol = 'UDP'
            Profile = 'Domain'

        }

        $CMBasicInboundRulesTCPEphemeral = @{

            DisplayName = 'SCCM Basic Inbound IP Rules (TCP Ephemeral)'
            Enabled = 'True'
            Direction = 'Inbound'
            Action = 'Allow'
            LocalPort = '49152-65535'
            Protocol = 'TCP'
            Profile = 'Domain'

        }

        $CMBasicOutboundRulesTCPEphemeral = @{

            DisplayName = 'SCCM Basic Outbound IP Rules (TCP Ephemeral)'
            Enabled = 'True'
            Direction = 'Outbound'
            Action = 'Allow'
            LocalPort = '49152-65535'
            Protocol = 'TCP'
            Profile = 'Domain'

        }
        $Session = New-CimSession -ComputerName $Comp
        Try{
            Write-Verbose ("Validating rule " + $CMBasicInboundRulesTCP.DisplayName)
            Get-NetFirewallRule $CMBasicInboundRulesTCP.DisplayName -CimSession $Session -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicInboundRulesTCP.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule -CimSession $Session @CMBasicInboundRulesTCP
        }

        Try{
            Write-Verbose ("Validating rule " + $CMBasicOutboundRulesTCP.DisplayName)
            Get-NetFirewallRule $CMBasicOutboundRulesTCP.DisplayName -CimSession $Session -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicOutboundRulesTCP.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule  -CimSession $Session @CMBasicOutboundRulesTCP
        }

        Try{
            Write-Verbose ("Validating rule " + $CMBasicInboundRulesUDP.DisplayName)
            Get-NetFirewallRule -CimSession $Session $CMBasicInboundRulesUDP.DisplayName -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicInboundRulesUDP.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule -CimSession $Session @CMBasicInboundRulesUDP
        }

        Try{
            Write-Verbose ("Validating rule " + $CMBasicOutboundRulesUDP.DisplayName)
            Get-NetFirewallRule -CimSession $Session $CMBasicOutboundRulesUDP.DisplayName -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicOutboundRulesUDP.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule -CimSession $Session @CMBasicOutboundRulesUDP
        }

        Try{
            Write-Verbose ("Validating rule " + $CMBasicInboundRulesTCPEphemeral.DisplayName)
            Get-NetFirewallRule -CimSession $Session $CMBasicInboundRulesTCPEphemeral.DisplayName -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicInboundRulesTCPEphemeral.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule -CimSession $Session @CMBasicInboundRulesTCPEphemeral
        }

        Try{
            Write-Verbose ("Validating rule " + $CMBasicOutboundRulesTCPEphemeral.DisplayName)
            Get-NetFirewallRule -CimSession $Session $CMBasicOutboundRulesTCPEphemeral.DisplayName -ErrorAction Stop
        }
        Catch [System.Exception]{
            Write-Verbose ("Rule " + $CMBasicOutboundRulesTCPEphemeral.DisplayName + "does not exist.  Creating Rule.")
            New-NetFirewallRule -CimSession $Session @CMBasicOutboundRulesTCPEphemeral
        }
        
        $ServicesArray = 'RDC','Web-Server','Web-WMI','NET-Framework-Core','BITS','BITS-IIS-Ext','BITS-Compact-Server','RSAT-Bits-Server'               
               
        ForEach($Service in $ServicesArray){

            If((Get-WindowsFeature -Name $Service -ComputerName $Comp).IsEnabled -ne $true){
            
                Write-Verbose ("The Service " + $Service + " is not installed.  Installing.") -Verbose
                Install-WindowsFeature -Name $Service -ComputerName $Comp
            
            }

        }
           
    }

}