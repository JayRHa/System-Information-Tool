|**Jannik Reinhard**|[![Twitter Follow](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/jannik_reinhard)  [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/jannik-r/)  [![Website](https://img.shields.io/badge/website-000000?style=for-the-badge&logo=About.me&logoColor=white)](https://jannikreinhard.com/)|

# System Information Tool
The System Information Tool is a software that displays various system information, such as the serial number, IP address, username and logged-in user, and many more. It also provides functions for troubleshooting and analyzing problems with Intune Management and Intune Management Extension. In addition, custom scripts for self-service support can be added and provided to them user. The tool is thus a useful resource for users who need quick access to system information and assistance in troubleshooting problems.

![Tool View](https://github.com/JayRHa/System-Information-Tool/blob/main/UI/.images/toolView.png)

## Installing the application
In the repo there is an installation wrapper that creates a start menu entry and unblocks the dlls.
To install the UI for the following steps out:
- Download the repository
- Execute the setup script

```PowerShell
Install-SystemInformationTool.ps1
```

## Start the UI
- If you have installed the System Information Tool then search in the start menue "System Information Tool" 
- if you not installed the System Information Tool than make sure that the dlls are unblocked and execute the "Start-SystemInformationTool.ps1"

## Features
###  Informarion View
You can see an overview of different system attributes like Hostname, Ips, SerialNr., Ram and many more
![Tool View](https://github.com/JayRHa/System-Information-Tool/blob/main/UI/.images/toolView.png)

###  Intune and support actions
This feature provides you different actions to troubleshoot and fix the intune management extension.

You can add, change and delete custom attribute to a multiple devices device
![Intune](https://github.com/JayRHa/System-Information-Tool/blob/main/UI/.images/intune.png)

### Trigger deive action
You can include your custom script and self service actions on an realy easy way to this tool.
![Support](https://github.com/JayRHa/System-Information-Tool/blob/main/UI/.images/support.png)
To add self service actions you have to place the powershell script in the script folder and add to the "_actions.json" the action name and the script name
![Action](https://github.com/JayRHa/System-Information-Tool/blob/main/UI/.images/action.png)


