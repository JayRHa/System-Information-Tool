<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: uiHandler
Description:
handling of the ui actions
Release notes:
1.0 :
- Init
#>

########################################################################################
###################################### UI Actions ######################################
########################################################################################
### Init
function New-UiInti {
    # Set Lable Text
    $WPFlblTitel.Content = $global:ToolName
    $WPFlblAuthor.Content = "by $($global:Url)"

    # Inti Images
    Set-UiImages

    # Init close button
    Add-XamlEvent -object $WPFbtnClose -event "Add_Click" -scriptBlock {$global:formMainForm.Close() | out-null}

    # Init Info
    Set-SysInfo
    Set-ButtonsToCopy
    
    # Init Company Portal Buttons
    Set-UiCompanyPortalButton

    # Set Self Service Action
    Set-SelfServiceActions
    Add-XamlEvent -object $WPFDataGridSelfService -event "Add_GotMouseCapture" -scriptBlock {Invoke-SelfService -item $this.CurrentItem}

    return $true
}

function Set-ButtonsToCopy {
    Add-XamlEvent -object $WPFlblHostname -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblHostname.Content}
    Add-XamlEvent -object $WPFlblSerial -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblSerial.Content}
    Add-XamlEvent -object $WPFlblModel -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblModel.Content}
    Add-XamlEvent -object $WPFlblMemory -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblMemory.Content}
    Add-XamlEvent -object $WPFlblVersion -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblVersion.Content}
    Add-XamlEvent -object $WPFlblUser -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblUser.Content}
    Add-XamlEvent -object $WPFlblSync -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblSync.Content}
    Add-XamlEvent -object $WPFlblUptime -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblUptime.Content}
    Add-XamlEvent -object $WPFlblWifi -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblWifi.Content}
    Add-XamlEvent -object $WPFlblip -event "Add_MouseDoubleClick" -scriptBlock { Set-Clipboard $WPFlblip.Content}
}

function Set-SysInfo {
    $systemInfo = Get-SysInfo

    $WPFlblHostname.Content = $systemInfo.Hostname
    $WPFlblSerial.Content = $systemInfo.SerialNr
    $WPFlblModel.Content = $systemInfo.Model
    $WPFlblMemory.Content = $systemInfo.Memory
    $WPFlblVersion.Content = $systemInfo.WindowsVersion
    $WPFlblUser.Content = $systemInfo.CurrentUser + " / " + $systemInfo.EnrolledUser
    $WPFlblSync.Content = $systemInfo.LastIntuneSync
    $WPFlblUptime.Content =$systemInfo.Uptime
    $WPFlblWifi.Content = $systemInfo.WifiSsid
    if($systemInfo.LanTest){$WPFpicLan.source = "$global:Path\libaries\icon\on.png"}else{$WPFpicLan.source = "$global:Path\libaries\icon\off.png"}
    if($systemInfo.WifiTest){$WPFpicWifi.source = "$global:Path\libaries\icon\on.png"}else{$WPFpicWifi.source = "$global:Path\libaries\icon\off.png"}
    if($systemInfo.InternetTest){$WPFpicInternet.source = "$global:Path\libaries\icon\on.png"}else{$WPFpicInternet.source = "$global:Path\libaries\icon\off.png"}
    if($systemInfo.VpnTest){$WPFpicVpv.source = "$global:Path\libaries\icon\on.png"}else{$WPFpicVpv.source = "$global:Path\libaries\icon\off.png"}
    $WPFlblip.Content = ($systemInfo.Ips | out-string)
}

function Set-UiCompanyPortalButton {
    # Company Portal
    Add-XamlEvent -object $WPFbtnSyncApps -event "Add_Click" -scriptBlock {Sync-Apps}
    Add-XamlEvent -object $WPFbtnSyncCompliance -event "Add_Click" -scriptBlock {Sync-Complance}
    Add-XamlEvent -object $WPFbtnOpenCompanyPortal -event "Add_Click" -scriptBlock {Open-CompanyPortal}
    Add-XamlEvent -object $WPFbtnOpenQuickAssist -event "Add_Click" -scriptBlock {Open-QuickAssist}
    Add-XamlEvent -object $WPFbtnConnectionTest -event "Add_Click" -scriptBlock {Invoke-IntuneConnectionTest}
    Add-XamlEvent -object $WPFbtnCollectDiagnosticLogs -event "Add_Click" -scriptBlock {Get-DiagnosticLogs}
    Add-XamlEvent -object $WPFbtnImeRestart -event "Add_Click" -scriptBlock {Restart-Ime}
    Add-XamlEvent -object $WPFbtnUserCert -event "Add_Click" -scriptBlock {Get-UserCert}
    Add-XamlEvent -object $WPFbtnMachineCert -event "Add_Click" -scriptBlock {Get-MachineCert}
    Add-XamlEvent -object $WPFbtnImeRegistry -event "Add_Click" -scriptBlock {Get-ImeRegistry}
}

function Set-SelfServiceActions {  
    $global:actionItems = (Get-Content "$global:Path\scripts\_actions.json" | ConvertFrom-Json).actions
    $WPFDataGridSelfService.ItemsSource = $global:actionItems
}

function Invoke-SelfService {
    param (
        [Parameter(Mandatory = $true)]$item
    
    )
    Start-Process powershell.exe -ArgumentList "& '$global:Path\scripts\$($item.script)'"
}

function Set-UiImages {
    $WPFpicLogo.source = "$global:Path\libaries\icon\logo.jpg"
}