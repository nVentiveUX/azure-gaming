$webClient = new-object System.Net.WebClient

################################################################################
# Registry tweaks

Write-Output "Make the password and account of admin user never expire."
Set-LocalUser -Name $admin_username -PasswordNeverExpires $true -AccountNeverExpires

Write-Output "Make the admin login at startup."
$registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
Set-ItemProperty $registry "DefaultUsername" -Value $admin_username -type String
Set-ItemProperty $registry "DefaultPassword" -Value $admin_password -type String

# From https://stackoverflow.com/questions/9701840/how-to-create-a-shortcut-using-powershell
Write-Output "Create disconnect shortcut under C:\disconnect.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\disconnect.lnk")
$Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
$Shortcut.Arguments = "1 /dest:console"
$Shortcut.Save()

################################################################################
# Install NVIDIA drivers

Write-Output "Installing Nvidia Driver"
$driver_file = "nvidia-driver.exe"
# From https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup#nvidia-grid-drivers
$url = "https://go.microsoft.com/fwlink/?linkid=874181"

Write-Output "Downloading Nvidia M60 driver from URL $url"
$webClient.DownloadFile($url, "$PSScriptRoot\$driver_file")

Write-Output "Installing Nvidia M60 driver from file $PSScriptRoot\$driver_file"
Start-Process -FilePath "$PSScriptRoot\$driver_file" -ArgumentList "-s", "-noreboot" -Wait
Start-Process -FilePath "C:\NVIDIA\$nvidia_version\setup.exe" -ArgumentList "-s", "-noreboot" -Wait

################################################################################
# Disabling Hyper-V Video

$url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
$compressed_file = "DeviceManagement.zip"
$extract_folder = "DeviceManagement"

Write-Output "Downloading Device Management Powershell Script from $url"
$webClient.DownloadFile($url, "$PSScriptRoot\$compressed_file")
Unblock-File -Path "$PSScriptRoot\$compressed_file"

Write-Output "Extracting Device Management Powershell Script"
Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$extract_folder" -Force

Write-Output "Disabling Hyper-V Video"
Import-Module "$PSScriptRoot\$extract_folder\DeviceManagement.psd1"
Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false

################################################################################
# Disable TCC

$nvsmi = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
$gpu = & $nvsmi --format=csv,noheader --query-gpu=pci.bus_id
& $nvsmi -g $gpu -fdm 0

################################################################################
# Install-VirtualAudio

$compressed_file = "VBCABLE_Driver_Pack43.zip"
$driver_folder = "VBCABLE_Driver_Pack43"
$driver_inf = "vbMmeCable64_win7.inf"
$hardward_id = "VBAudioVACWDM"

Write-Output "Downloading Virtual Audio Driver"
$webClient.DownloadFile("http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$PSScriptRoot\$compressed_file")
Unblock-File -Path "$PSScriptRoot\$compressed_file"

Write-Output "Extracting Virtual Audio Driver"
Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$driver_folder" -Force

$wdk_installer = "wdksetup.exe"
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe"

Write-Output "Downloading Windows Development Kit installer"
$webClient.DownloadFile("http://go.microsoft.com/fwlink/p/?LinkId=526733", "$PSScriptRoot\$wdk_installer")

Write-Output "Downloading and installing Windows Development Kit"
Start-Process -FilePath "$PSScriptRoot\$wdk_installer" -ArgumentList "/S" -Wait

$cert = "vb_cert.cer"
$url = "https://github.com/nVentiveUX/azure-gaming/raw/master/$cert"

Write-Output "Downloading vb certificate from $url"
$webClient.DownloadFile($url, "$PSScriptRoot\$cert")

Write-Output "Importing vb certificate"
Import-Certificate -FilePath "$PSScriptRoot\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"

Write-Output "Installing virtual audio driver"
Start-Process -FilePath $devcon -ArgumentList "install", "$PSScriptRoot\$driver_folder\$driver_inf", $hardward_id -Wait

################################################################################
# Install Steam

$steam_exe = "steam.exe"
Write-Output "Downloading steam into path $PSScriptRoot\$steam_exe"
$webClient.DownloadFile("https://steamcdn-a.akamaihd.net/client/installer/SteamSetup.exe", "$PSScriptRoot\$steam_exe")
Write-Output "Installing steam"
Start-Process -FilePath "$PSScriptRoot\$steam_exe" -ArgumentList "/S" -Wait

Write-Output "Cleaning up steam installation file"
Remove-Item -Path $PSScriptRoot\$steam_exe -Confirm:$false

################################################################################
# Install Parsec

$parsec_exe = "parsec-windows.exe"
Write-Output "Downloading Parsec into path $PSScriptRoot\$parsec_exe"
$webClient.DownloadFile("https://s3.amazonaws.com/parsec-build/package/parsec-windows.exe", "$PSScriptRoot\$parsec_exe")
Write-Output "Installing Parsec"
Start-Process -FilePath "$PSScriptRoot\$parsec_exe" -ArgumentList "/S" -Wait

Write-Output "Cleaning up Parsec installation file"
Remove-Item -Path $PSScriptRoot\$parsec_exe -Confirm:$false

################################################################################
# Install Epic Games Launcher

$epic_msi = "EpicGamesLauncherInstaller.msi"
Write-Output "Downloading Epic Games Launcher into path $PSScriptRoot\$epic_msi"
$webClient.DownloadFile("https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi", "$PSScriptRoot\$epic_msi")
Write-Output "Installing Epic Games Launcher"
Start-Process -FilePath "$PSScriptRoot\$epic_msi" -ArgumentList "/quiet" -Wait

Write-Output "Cleaning up Epic Games Launcher installation file"
Remove-Item -Path $PSScriptRoot\$epic_msi -Confirm:$false

################################################################################
# Restart computer

Write-Host -ForegroundColor Yellow 'Please restart Computer.'
