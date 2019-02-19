<#
.SYNOPSIS
    Bootstrap an Azure VM running Windows 10.

.DESCRIPTION
    This script requires administrative privileges.
#>

function Get-UtilsScript ($script_name) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $url = "https://github.com/nVentiveUX/azure-gaming/raw/master/$script_name"
    Write-Output "Downloading utils script from $url"
    (New-Object System.Net.WebClient).DownloadFile($url, "$PSScriptRoot\$script_name")
}

$script_name = "utils.psm1"
Get-UtilsScript $script_name
Import-Module "$PSScriptRoot\$script_name"

Manage-Display-Adapters
Disable-TCC
Install-VPN
Install-VirtualAudio
Install-LanguageExperiencePack
Install-Steam
Install-EpicGameLauncher
Install-Parsec

Write-Host -ForegroundColor Yellow "Would you like to reboot now?"
$Readhost = Read-Host "(Y/N) Default is no"
Switch ($ReadHost) {
    Y {Write-host "Rebooting now..."; Start-Sleep -s 2; Restart-Computer}
    N {Write-Host "Exiting script in 5 seconds."; Start-Sleep -s 5}
    Default {Write-Host "Exiting script in 5 seconds"; Start-Sleep -s 5}
}

# End of script
exit
