<#
.SYNOPSIS
    A script that can be used to cleanup devices from AAD, Intune and Autopilot
.DESCRIPTION
    A script that can be used to cleanup devices from AAD, Intune and Autopilot
    You can choose which areas to cleanup by using the available switches. If no switch is set, all areas will be cleaned up
.NOTES
    The scrip requires the use of some of the Microsoft Graph PowerShell modules
.PARAMETER ComputerName
    The name of the computer to remove
.PARAMETER AAD
    Remove the device from Azure AD
.PARAMETER Intune
    Remove the device from Intune
.PARAMETER Autopilot
    Remove the device from Autopilot
.PARAMETER Tenant
    The tenant to connect to. The default is the tenant of the current user (BEWARE OF THIS IF USING GUEST ACCOUNTS!)
.PARAMETER Force
    Skip confirmation prompts. This is required for the script to run in an unattended mode
.PARAMETER Whatif
    Show what would happen if the script was run
.PARAMETER Verbose
    Show verbose output - This will output the device records that are found
.EXAMPLE
    ./Delete-Device_from_Autopilot_Intune_AAD_v2 -ComputerName VM-TST-01 -Tenant Macaw.nl -Verbose

.EXAMPLE
    ("VM-TST-01", "VM-TST-02") | ./Delete-Device_from_Autopilot_Intune_AAD_v2

#>


[CmdletBinding(DefaultParameterSetName = 'All', SupportsShouldProcess = $true)]
Param
(
    [Parameter(ParameterSetName = 'All', Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
    [Parameter(ParameterSetName = 'Individual', Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
    [String[]]$ComputerName,
    [Parameter(ParameterSetName = 'Individual')]
    [switch]$AAD,
    [Parameter(ParameterSetName = 'Individual')]
    [switch]$Intune,
    [Parameter(ParameterSetName = 'Individual')]
    [switch]$Autopilot,
    [Parameter(ParameterSetName = 'Individual')]
    [Parameter(ParameterSetName = 'All')]
    [string]$Tenant = "",
    [Parameter(ParameterSetName = 'Individual')]
    [Parameter(ParameterSetName = 'All')]
    [switch]$Force
)


Begin {
    Function _Confirmation {
    
        Write-Host "Are you sure? [Y] Yes  [A] Yes to All  [N] Skip [H] Halt operation(s) " -NoNewline
        :prompt while ($true) {
            $key = [console]::ReadKey($true).Key
            Switch ($key) {
                "Y" {
                    Write-Host "Y"
                    break prompt
                }
                "A" {
                    Write-Host "A"
                    $global:LocalForce = $true
                    break prompt
                }
                "N" {
                    Write-Host "N"
                    return $false
                }
                "H" {
                    Write-Host "H"
                    Throw "Operation terminated by user"
                }
            }
        }
        $true
    }

    Function Import-Requiredmodules {
        Param(
            [Switch]$Aad
        )

        Write-Host "Importing modules… " -NoNewline
        # Always import Intune module
        Import-Module Microsoft.Graph.Intune -ErrorAction Stop
        If ($Aad) {
            Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
            
        }
        Write-Host "Success" -ForegroundColor Green
    }

    Function Connect-WithAzure {
        Param (
            [Parameter(Mandatory = $false)]
            [string]$Tenant = "",
            [Parameter(Mandatory = $true)]
            [string[]]$RequiredRoles
        )

        Write-Host "Authenticating with MS Graph… " -NoNewline
        $parameters = @{
            Scopes      = $requiredRoles
            ErrorAction = "Stop"
        }
        if (-Not [string]::IsNullOrEmpty($Tenant)) {
            $parameters += @{
                TenantId = $Tenant
            }
        }
        [Void](Connect-MgGraph @parameters)
        $context = Get-MgContext
        if ($requiredRoles | Where-Object { $context.Scopes -notcontains $_ }) {
            Throw "Required role is missing from the MS Graph Cmdline App in Azure"
        }
        Write-Host "(connected to tenantid: $($context.TenantId)) " -NoNewline
        Write-Host "Success" -ForegroundColor Green
    }

    Function Get-AadDevices {
        Param(
            [Parameter(Mandatory = $true)]
            [string[]]$ComputerName
        )

        Write-host "Retrieving " -NoNewline
        Write-host "Azure AD " -ForegroundColor Yellow -NoNewline
        Write-host ("device record/s for {0}… " -f $ComputerName) -NoNewline
        [array]$AzureADDevices = Get-MgDevice –filter "displayname eq '$ComputerName'" –ErrorAction Stop
        switch ($AzureADDevices.Count) {
            { $_ -eq 1 } {
                Write-Host "Success" -ForegroundColor Green   
            }
            { $_ -gt 1 } {
                Write-Host "Success" -ForegroundColor Green
                Write-Host "Found $($AzureADDevices.Count) devices with the same name" –ForegroundColor Yellow
            }
            { $_ -eq 0 } {
                Write-Host "Not found!" –ForegroundColor Red
            }
        }
        Write-Verbose ($AzureADDevices | Select-Object DisplayName, Id, RegistrationDateTime, ApproximateLastSignInDateTime | Out-String)
        return $AzureADDevices
    }

    Function Remove-AadDevice {
        [cmdletbinding(SupportsShouldProcess = $true)]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
            [Object]$Device
        )
        Begin {
            $global:LocalForce = $global:Force
        }
        Process {
            if ($PSCmdlet.ShouldProcess(("{0}({1})" -f $Device.DisplayName, $Device.Id), "Removing device")) {
                Write-Host "Deleting " -NoNewline
                Write-Host "Azure AD " -ForegroundColor Yellow -NoNewline
                Write-Host ("device record for {0}({1})… " -f $Device.DisplayName, $Device.Id) -NoNewline
                if ($LocalForce -or (_Confirmation)) {
                    [Void](Remove-MgDevice -DeviceId $Device.Id -ErrorAction Stop)
                    if (-Not $WhatIfPreference) { Write-Host "Success" -ForegroundColor Green }
                }
                else {
                    Write-host "Skipping!" -ForegroundColor Yellow
                }
            }
        }
    }

    Function Get-IntuneDevices {
        Param(
            [Parameter(Mandatory = $true)]
            [string[]]$ComputerName
        )

        Write-host "Retrieving " -NoNewline
        Write-host "Intune " -ForegroundColor Yellow -NoNewline
        Write-host "managed device record/s… " -NoNewline
        [array]$IntuneDevices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$ComputerName'"
        switch ($IntuneDevices.Count) {
            { $_ -eq 1 } {
                Write-Host "Success" -ForegroundColor Green   
            }
            { $_ -gt 1 } {
                Write-Host "Success" -ForegroundColor Green
                Write-Host "Found $($IntuneDevices.Count) devices with the same name" -ForegroundColor Yellow
            }
            { $_ -eq 0 } {
                Write-Host "Not found!" -ForegroundColor Red
            }
        }
        Write-Verbose ($IntuneDevices | Select-Object DeviceName, Id, LastSyncDateTime | Out-String)
        return $IntuneDevices
    }

    Function Remove-IntuneDevice {
        [cmdletbinding(SupportsShouldProcess = $true)]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
            [Object]$Device
        )
        Begin {
            $global:LocalForce = $global:Force
        }
        Process {
            if ($PSCmdlet.ShouldProcess(("{0}({1})" -f $Device.DeviceName, $Device.Id), "Removing device")) {
                Write-Host "Deleting " -NoNewline
                Write-Host "Intune " -ForegroundColor Yellow -NoNewline
                Write-Host ("device record for {0}({1})…" -f $Device.DeviceName, $Device.Id)
                if ($LocalForce -or (_Confirmation)) {
                    [Void](Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $Device.Id -ErrorAction Stop)
                    if (-Not $WhatIfPreference) { Write-Host "Success" -ForegroundColor Green }
                }
                else {
                    Write-host "Skipping!" -ForegroundColor Yellow
                }
            }
        }
    }

    Function Get-AutoPilotDevice {
        Param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
            [Object]$intuneDevice
        )

        Begin {
            Write-host "Retrieving " -NoNewline
            Write-host "Autopilot " -ForegroundColor Yellow -NoNewline
            Write-host "device record/s… " -NoNewline
        } Process {
            $AutoPilotDevice = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -Filter ("contains(serialNumber,'{0}')" -f $IntuneDevices.SerialNumber)
            Write-Host "Success" -ForegroundColor Green
            return $AutoPilotDevice
        }
    }

    Function Remove-AutoPilotDevice {
        [cmdletbinding(SupportsShouldProcess = $true)]
        Param(
            [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
            [Object]$Device
        )
        Begin {
            $global:LocalForce = $global:Force
        }
        Process {
            if ($PSCmdlet.ShouldProcess(("{0}({1})" -f $Device.Id, $Device.SerialNumber), "Removing device")) {
                Write-Host "Deleting " -NoNewline
                Write-Host "Autopilot " -ForegroundColor Yellow -NoNewline
                Write-Host "SerialNumber: $($Device.value.serialNumber)  |  Model: $($Device.Model)  |  Id: $($Device.Id)  |  GroupTag: $($Device.GroupTag)  |  ManagedDeviceId: $($device.managedDeviceId) …"
                if ($LocalForce -or (_Confirmation)) {
                    [Void](Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $Device.Id -ErrorAction Stop)
                    Write-host "Would remove"
                    if (-Not $WhatIfPreference) { Write-Host "Success" -ForegroundColor Green }
                }
                else {
                    Write-host "Skipping!" -ForegroundColor Yellow
                }
            }
        }
    }


    #### Main
    if ($PSCmdlet.ParameterSetName -eq "All") {
        $AAD = $true
        $Intune = $true
        $Autopilot = $true
    }

    # Set the value of -Force globally
    $global:Force = $Force

    Try {
        # Import modules
        if ($AAD) { Import-Requiredmodules -Aad } else { Import-Requiredmodules }

        # Connect with Microsoft Graph
        Connect-WithAzure -Tenant $Tenant -RequiredRoles ("Device.ReadWrite.All", "DeviceManagementManagedDevices.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All")

    }
    catch {
        Write-Host "Error!" -ForegroundColor Red
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
        Exit 1
    }

}
Process {
    Try {
        # Work Intune
        $IntuneDevices = Get-IntuneDevices -ComputerName $ComputerName
        if ($Intune -and $IntuneDevices) {
            $IntuneDevices | Remove-IntuneDevice -WhatIf:$WhatIfPreference
        }

        # Work Autopilot
        if ($Autopilot -and $IntuneDevices.Count -ge 1) {
            $autoPilotDevices = $IntuneDevices | Get-AutoPilotDevice
            Write-Verbose ($AutoPilotDevices | Select-Object AzureActiveDirectoryDeviceId, ManagedDeviceId, SerialNumber, SystemFamily | Out-String)
            $AutoPilotDevices | Remove-AutoPilotDevice -WhatIf:$WhatIfPreference
        }

        # Work AAD
        if ($AAD) {
            $AadDevices = Get-AadDevices -ComputerName $ComputerName
            if ($AadDevices) { $AadDevices | Remove-AadDevice -WhatIf:$WhatIfPreference }
        }
    }
    catch {
        Write-Host "Error!" -ForegroundColor Red
        Write-Host "$($_.Exception.Message)" -ForegroundColor Red
        Exit 1
    }
}