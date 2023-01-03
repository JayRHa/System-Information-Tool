<#PSScriptInfo
.VERSION 2.0
.GUID 6a13baa9-ffa4-4643-98c0-f33c6c6c2220
.AUTHOR Jannik Reinhard
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.PROJECTURI https://github.com/JayRHa/Intune-Scripts/tree/main/Check-AutopilotPrerequisites
.ICONURI
.EXTERNALMODULEDEPENDENCIES 
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
.PRIVATEDATA
#>

<# 
.DESCRIPTION 
 Checking if all prerequisites are fullfiled befor starting the enrollment process 
.INPUTS
 None required
.OUTPUTS
 None
.NOTES
 Author: Jannik Reinhard (jannikreinhard.com)
 Twitter: @jannik_reinhard
 Release notes:
  Version 2.0: Init + Add dynapse endpoint list from ms in addition
#> 

$ProgressPreference = "SilentlyContinue"
function Get-NetworkInformation {
    $networkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -namespace "root\CIMV2" -computername "." -Filter "IPEnabled = 'True' AND DHCPEnabled ='True'" 
    foreach ($networkAdapter in $networkAdapters) 
    {  
        Write-Host -ForegroundColor green "$($networkAdapter.Caption):"

        $ipAddress = ((Get-ItemProperty -Path ("HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\{0}" -f $networkAdapter.SettingID) -Name DhcpIPAddress).DhcpIPAddress)
        $dhcpServer = ((Get-ItemProperty -ErrorAction SilentlyContinue -Path ("HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\Parameters\Interfaces\{0}" -f $networkAdapter.SettingID) -Name DhcpServer).DhcpServer)
        Write-Host "  IP address : $ipAddress"
        Write-Host "  DHCP server: $dhcpServer"
    }
}

function Get-ComputerInformation {
    $autopilotCache = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Provisioning\AutopilotPolicyCache" -Name "PolicyJsonCache"
    $autopilotCache = $autopilotCache | ConvertFrom-Json
    $autopilotCache = $autopilotCache.DeploymentProfileName
    $osEdition = systeminfo.exe
    $osEdition = ($osEdition[2].Replace("OS Name:","").trim()).Replace("Microsoft ","")
    $computerInfo = get-computerinfo
    $tpmInfo = get-tpm
    
    $windowsVerison = @(
        "Windows 10 Enterprise", "Windows 10 Education", "Windows 10 Pro for Workstations", "Windows 10 Pro Education", "Windows 10 Pro" ,"Windows 11 Enterprise", "Windows 11 Education", "Windows 11 Pro for Workstations", "Windows 11 Pro Education", "Windows 11 Pro"
    )
    
    Write-Host -NoNewline "  Windows Edition :     "
    if($windowsVerison.Contains($($osEdition))){
        Write-Host -ForegroundColor green $osEdition
    }else{
        Write-Host -ForegroundColor red $osEdition
    }
    Write-Host "  Windows Version :     $($computerInfo.WindowsVersion) $($computerInfo.OSDisplayVersion)"
    Write-Host "  Windows InstallDate : $($computerInfo.OsInstallDate)"
    Write-Host "  Bios Version :        $($computerInfo.BiosBIOSVersion)"
    Write-Host "  Bios Status :         $($computerInfo.BiosStatus)"
    Write-Host "  Bios Serialnumber :   $($computerInfo.BiosSeralNumber)"
    Write-Host "  Os Serialnumber :     $($computerInfo.OsSerialNumber)"
    Write-Host "  Hostname :            $($computerInfo.CsName)"
    Write-Host "  Keyboardlayout :      $($computerInfo.KeyboardLayout)"
    Write-Host "  Timezone :            $($computerInfo.TimeZone)"
    Write-Host "  Tpm present :         $($tpmInfo.TpmPresent)"
    Write-Host "  Tpm ready :           $($tpmInfo.TpmReady)"
    Write-Host "  Tpm enabled :         $($tpmInfo.TpmEnabled)"
    if (-not $autopilotCache.DeploymentProfileName) {
        Write-Host "  Cached AP Profile :   Not Present"
        
    }else{
        Write-Host "  Cached AP Profile :   Assigned" 
        Write-Host "  Autopilot Profile : $autopilotCache"   
    }

}

function Get-ConnectionTest {
    param(
		[Parameter(Mandatory)]
		$connections,
		
		[Parameter(Mandatory)]
		[int]$port
	)

    #443
    Write-Host -ForegroundColor blue "Test port $port :"

    $connections | ForEach-Object {
        $result = (Test-NetConnection -Port $port -ComputerName $_.uri)    
        Write-Host -NoNewline "  $($_.area): $($result.ComputerName) ($($result.RemoteAddress)): "
        if($result.TcpTestSucceeded) {
            Write-Host -ForegroundColor Green $result.TcpTestSucceeded
        }else{
            Write-Host -ForegroundColor Red $result.TcpTestSucceeded
        }
    }
    Write-Host
}

function Get-OtherConnectionsTested {
    param(
		[Parameter(Mandatory)]
		$connections
	)

    $msEndpoints = @()
    (invoke-restmethod -Uri ("https://endpoints.office.com/endpoints/WorldWide?ServiceAreas=MEM`&clientrequestid=" + ([GUID]::NewGuid()).Guid)) | ?{$_.ServiceArea -eq "MEM" -and $_.urls} | select -ExpandProperty urls | ForEach-Object {
        #$msEndpoints += $_.Replace("*.", "")
        $msEndpoints += $_
    }
    $msEndpoints = $msEndpoints | Where-Object {$_ -notmatch "\*." -and $_ -notin $connections}    
    Write-Host -ForegroundColor blue "Check all other connections (443):"

    $msEndpoints | ForEach-Object {
        $result = (Test-NetConnection -Port 443 -ComputerName $_)    
        Write-Host -NoNewline "  Other Connections: $($result.ComputerName) ($($result.RemoteAddress)): "
        if($result.TcpTestSucceeded) {
            Write-Host -ForegroundColor Green $result.TcpTestSucceeded
        }else{
            Write-Host -ForegroundColor Red $result.TcpTestSucceeded
        }
    }
    Write-Host
}

###########################################################################
################################# START ###################################
###########################################################################
$connections443 = @(
    [pscustomobject]@{uri='www.msftconnecttest.com';Area='Connection test'},

    [pscustomobject]@{uri='login.microsoftonline.com';Area='Microsoft authentication'},
    [pscustomobject]@{uri='aadcdn.msauth.net';Area='Microsoft authentication'},

    [pscustomobject]@{uri='enterpriseregistration.windows.net';Area='Intune'},
    [pscustomobject]@{uri='enterpriseenrollment-s.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='enterpriseEnrollment.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='enrollment.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='portal.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='config.office.com';Area='Intune'},
    [pscustomobject]@{uri='graph.windows.net';Area='Intune'},
    [pscustomobject]@{uri='m.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='fef.msuc03.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='mam.manage.microsoft.com';Area='Intune'},
    [pscustomobject]@{uri='manage.microsoft.com';Area='Intune'},

    [pscustomobject]@{uri='ztd.dds.microsoft.com';Area='Autopilot Service'},
    [pscustomobject]@{uri='cs.dds.microsoft.com';Area='Autopilot Service'},
    [pscustomobject]@{uri='login.live.com';Area='Autopilot Service'},

    [pscustomobject]@{uri='activation.sls.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='licensing.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='validation-v2.sls.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='validation.sls.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='purchase.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='purchase.md.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='licensing.md.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='go.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='displaycatalog.md.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='displaycatalog.mp.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='activation-v2.sls.microsoft.com';Area='License activation'},
    [pscustomobject]@{uri='activation.sls.microsoft.com';Area='License activation'},

    [pscustomobject]@{uri='emdl.ws.microsoft.com';Area='Windows Update'},
    [pscustomobject]@{uri='dl.delivery.mp.microsoft.com';Area='Windows Update'},
    [pscustomobject]@{uri='update.microsoft.com';Area='Windows Update'},
    [pscustomobject]@{uri='fe2cr.update.microsoft.com';Area='Windows Update'},

    [pscustomobject]@{uri='autologon.microsoftazuread-sso.com';Area='Single sign-on'},

    [pscustomobject]@{uri='powershellgallery.com';Area='Powershell gallery'},

    [pscustomobject]@{uri='ekop.intel.com';Area='TPM check'},
    [pscustomobject]@{uri='ekcert.spserv.microsoft.com';Area='TPM check'},
    [pscustomobject]@{uri='ftpm.amd.com';Area='TPM check'},

    [pscustomobject]@{uri='naprodimedatapri.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='naprodimedatasec.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='naprodimedatahotfix.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='euprodimedatapri.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='euprodimedatasec.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='euprodimedatahotfix.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='approdimedatapri.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='approdimedatasec.azureedge.net';Area='Powershell and Win32'},
    [pscustomobject]@{uri='approdimedatahotfix.azureedge.net';Area='Powershell and Win32'},

    [pscustomobject]@{uri='v10c.events.data.microsoft.com';Area='Update Compliance'},
    [pscustomobject]@{uri='v10.vortex-win.data.microsoft.com';Area='Update Compliance'},
    [pscustomobject]@{uri='settings-win.data.microsoft.com';Area='Update Compliance'},
    [pscustomobject]@{uri='adl.windows.com';Area='Update Compliance'},
    [pscustomobject]@{uri='watson.telemetry.microsoft.com';Area='Update Compliance'},
    [pscustomobject]@{uri='oca.telemetry.microsoft.com';Area='Update Compliance'}       
)

$connections80 = @(
    [pscustomobject]@{uri='emdl.ws.microsoft.com';Area='Windows Update'},
    [pscustomobject]@{uri='dl.delivery.mp.microsoft.com';Area='Windows Update'},    

    [pscustomobject]@{uri='time.windows.com';Area='Time service'}
)



Write-Host -ForegroundColor Yellow "######################################"
Write-Host -ForegroundColor Yellow "# Start Autopilot prerequisite check #"
Write-Host -ForegroundColor Yellow "######################################"
Write-Host
Write-Host -ForegroundColor Yellow "---------------------------------"
Write-Host -ForegroundColor Yellow "|      Device information       |"
Write-Host -ForegroundColor Yellow "---------------------------------"
Get-ComputerInformation
Write-Host
Write-Host -ForegroundColor Yellow "---------------------------------"
Write-Host -ForegroundColor Yellow "| Networkinterface informations |"
Write-Host -ForegroundColor Yellow "---------------------------------"
Get-NetworkInformation
Write-Host
Write-Host -ForegroundColor Yellow "---------------------------------"
Write-Host -ForegroundColor Yellow "|        Connection Test        |"
Write-Host -ForegroundColor Yellow "---------------------------------"
Get-ConnectionTest -connections $connections443 -port 443
Get-ConnectionTest -connections $connections80 -port 80
Get-OtherConnectionsTested -connections ($connections80 + $connections443).uri
Write-Host
Write-Host -ForegroundColor Yellow "######################################"
Write-Host -ForegroundColor Yellow "#  Autopilot prerequisite check Done #"
Write-Host -ForegroundColor Yellow "######################################"
Read-Host "Press [Enter] to close"