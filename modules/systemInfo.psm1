<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Start-SystemInformationTool
Description:
Get the info and define the actions
Release notes:
1.0 :
- Init
#>
function Test-InternetConnection {
    if (Test-NetConnection -ComputerName www.google.com -Port 80 -InformationLevel Quiet) {return $True}
    else {return $False}
}

function Test-ConnectionType {
    param(
        [Parameter(Mandatory = $true)] $adapters,
        [Parameter(Mandatory = $true)] $test
    )

    foreach ($adapter in $adapters) {
        $nic = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
        if ($nic.Description -like $test) {
            return $True
        }
    }
    return $False
}


function Get-Ips {
    return (Get-WmiObject -Class Win32_NetworkAdapterConfiguration).IPAddress | Sort-Object
}

function Get-WiFiSSID {
    param(
        [Parameter(Mandatory = $true)] $adapters
    )

    foreach ($adapter in $adapters) {
        $nic = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.Index -eq $adapter.Index }
        if ($nic.Description -like "*Wireless*") {
            return $nic.SSID
        }
    }
    return ""
}

function Test-VPNConnection {
    $VPNConnection = Get-VpnConnection
    if ($VPNConnection.ConnectionStatus -eq "Connected") {
        return $true
    } else {
        return $false
    }
}

function Get-IntuneSyncTimestamp {
    $account = $((Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts")[0].Name).Replace("HKEY_LOCAL_MACHINE", "HKLM:")
    $time = (Get-ItemProperty -Path "$account\Protected\ConnInfo").ServerLastAccessTime
    $date = [datetime]::ParseExact($time, "yyyyMMddTHHmmssZ", $null)
    return $date.ToString("MM/dd/yyyy HH:mm:ss")
}


function Get-SysInfo {
    $computerInfo = get-computerinfo
    $adapters = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -ne 2 }
    $wifiSsid = Get-WiFiSSID -adapters $adapters
    $system = Get-WmiObject -Class Win32_ComputerSystem
    $osName = $(($computerInfo.OsName).Replace("Microsoft ", ""))
    $uptime = ((Get-WinEvent -ProviderName 'Microsoft-Windows-Kernel-Boot'| where {$_.ID -eq 27 -and $_.message -like "*0x0*"} -ea silentlycontinue)[0]).TimeCreated

    return @{
        Hostname            = $env:computername
        Model               = "$($system.Manufacturer) / $($system.Model)"
        Memory              = "$([Math]::Round(($system.TotalPhysicalMemory/ 1GB),1)) GB" 
        WindowsVersion      = "$osName $($computerInfo.OSDisplayVersion)"
        CurrentUser         = $env:username
        EnrolledUser        = $computerInfo.OsRegisteredUser
        LastIntuneSync      = Get-IntuneSyncTimestamp
        Uptime              = $uptime.ToString("MM/dd/yyyy HH:mm:ss")
        SerialNr            = (Get-ciminstance Win32_OperatingSystem).SerialNumber
        WifiSsid            = if($wifiSsid){$wifiSsid}else{"No Wifi connection"}
        LanTest             = Test-ConnectionType -adapters $adapters -test "*Ethernet*"
        WifiTest            = Test-ConnectionType -adapters $adapters -test "*Wireless*"
        InternetTest        = Test-InternetConnection
        VpnTest             = Test-VPNConnection
        Ips                 = Get-Ips
    }
}

### Actions
function Sync-Apps{
    $syncIme.open("intunemanagementextension://syncapp")
}

function Sync-Complance{
    $syncIme.open("intunemanagementextension://synccompliance")
}

function Open-CompanyPortal{
    explorer.exe shell:appsFolder\Microsoft.CompanyPortal_8wekyb3d8bbwe!App
}

function Open-QuickAssist{
    & "$env:systemroot\system32\quickassist.exe"
}

function Invoke-IntuneConnectionTest{  
    Start-Process powershell.exe -ArgumentList "& '$global:Path\scripts\Check-AutopilotPrerequisites.ps1'"
}

function Get-DiagnosticLogs{
    MdmDiagnosticsTool.exe -out "c:\temp\diagnostic"
    & explorer c:\temp\diagnostic
}

function Restart-Ime{
    Start-Process powershell.exe "-Command","Restart-Service -DisplayName 'Microsoft Intune Management Extension'" -Verb RunAs
}

function Get-MachineCert{
    certlm.msc
}

function Get-UserCert{
    Certmgr.msc
}

function Get-ImeRegistry{
    regedit
    [System.Windows.MessageBox]::Show('Navigate to: "HKLM\SOFTWARE\Microsoft\IntuneManagementExtension"')
}