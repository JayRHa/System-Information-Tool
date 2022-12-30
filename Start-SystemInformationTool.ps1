<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Start-SystemInformationTool
Description:
Start and init the SystemInformationTool
Release notes:
1.0 :
- Init
#>
###########################################################################################################
############################################ Functions ####################################################
###########################################################################################################
function Import-AllModules {
    foreach ($file in (Get-Item -path "$global:Path\modules\*.psm1")) {      
        $fileName = [IO.Path]::GetFileName($file) 
        if ($skipModules -contains $fileName) { Write-Warning "Module $fileName excluded"; continue; }
    
        $module = Import-Module $file -PassThru -Force -Global -ErrorAction SilentlyContinue
        if (-not ($module)) {return $false}
    }
    return $true
}

function Exit-Error {
    param (
        [Parameter(Mandatory = $true)]
        [String]$text
    )

    Write-Error $text 
    $global:messageScreen.Hide()
    $global:formAuth.Hide()
    Exit
}

###########################################################################################################
############################################## Start ######################################################
###########################################################################################################
### Variables
# General
$global:ToolName = "System Information Tool"
$global:Version = "1.0"
$global:Developer = "Jannik Reinhard"
$global:Url = "jannikreinhard.com"
$global:Path = $PSScriptRoot
$global:actionItems =$null

# Load custom modules
if (-not (Import-AllModules)) { Exit-Error -text "Error while loading the modules" }

# Load Dlls
if (-not (Import-Dlls)) {
    Write-Warning "Unblock all dlls and restart the powershell seassion"
    Exit-Error -text "Error while loading the dlls. Exit the script"
}

# Init Ui
try{
    $returnMainForm = New-XamlScreen -xamlPath ("$global:Path\xaml\ui.xaml")
    $global:formMainForm = $returnMainForm[0]
    $xamlMainForm = $returnMainForm[1]
    $xamlMainForm.SelectNodes("//*[@Name]") | % {Set-Variable -Name "WPF$($_.Name)" -Value $formMainForm.FindName($_.Name)}
    $global:formMainForm.add_Loaded({
        $global:formMainForm.Activate()
    })
}catch{
    Exit-Error -text "Failed to init UI"
}
if (-not (New-UiInti)) { Exit-Error -text "Failed to init UI" }
# Add Devices
$global:formMainForm.ShowDialog() | out-null