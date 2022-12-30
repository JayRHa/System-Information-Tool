<#
Version: 1.0
Author: Jannik Reinhard (jannikreinhard.com)
Script: Install-SystemInformationTool
Description:
Installation of the Tool
Release notes:
1.0 :
- Init
#>

# Program variables
$ProgramPath = "$env:LOCALAPPDATA\SystemInformationTool"

#############################################################################################################
#   Program files
#############################################################################################################

try{
    # Copy Files & Folders
    Write-Host "Copying / updating program files..."
    New-Item $ProgramPath -type Directory -Force | Out-Null
    Copy-Item ($PSScriptRoot + "\*") $ProgramPath -Force -Recurse
    Get-Childitem -Recurse $ProgramPath | Unblock-file
    Write-Host "Program files completed" -ForegroundColor green

    # Create Startmenu shortcut
    Write-Host "Creating / updating startmenu shortcut..."
    Copy-Item "$ProgramPath\libaries\System Information Tool.lnk" "$env:appdata\Microsoft\Windows\Start Menu\Programs\System Information Tool.lnk" -Force -Recurse
    Write-Host "Startmenu item completed" -ForegroundColor green

}catch{$_}

# Enter to exit
Write-Host "Installation completed!" -ForegroundColor green