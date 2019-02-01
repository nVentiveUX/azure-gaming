<#
.SYNOPSIS
    Bootstrap an Azure VM running Windows 10.

.DESCRIPTION
    This script requires administrative privileges.

    You can run this script from powershell admin prompt using the following:

      iex ((new-object net.webclient).DownloadString('https://github.com/nVentiveUX/azure-gaming/raw/master/utils.ps1'))
#>

################################################################################
# DO NOT EDIT BELOW THIS LINE                                                  #
################################################################################

$script_name = "utils.psm1"
Import-Module "C:\$script_name"

Disable-Devices
Disable-TCC
Install-VirtualAudio
Install-Steam
Install-EpicGameLauncher
Install-Parsec
Restart-Computer

