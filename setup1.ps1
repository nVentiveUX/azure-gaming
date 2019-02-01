<#
.SYNOPSIS
    Bootstrap an Azure VM running Windows 10.

.DESCRIPTION
    This script requires administrative privileges.

    You can run this script from powershell admin prompt using the following:

      iex ((new-object net.webclient).DownloadString('https://github.com/nVentiveUX/azure-gaming/raw/master/utils.ps1'))
#>

################################################################################
# CUSTOM VARS. PLEASE EDIT                                                     #
################################################################################

$admin_username = [Environment]::UserName
$admin_password = Read-Host 'Admin Password'
# From https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup#nvidia-grid-drivers
$nvidia_version = "411.81"

################################################################################
# DO NOT EDIT BELOW THIS LINE                                                  #
################################################################################


function Get-UtilsScript ($script_name) {
    $url = "https://github.com/nVentiveUX/azure-gaming/raw/master/$script_name"
    Write-Output "Downloading utils script from $url"
    $webClient = new-object System.Net.WebClient
    $webClient.DownloadFile($url, "C:\$script_name")
}

$script_name = "utils.psm1"
Get-UtilsScript $script_name
Import-Module "C:\$script_name"

Registy-tweaks
Install-NvidiaDriver
Restart-Computer

