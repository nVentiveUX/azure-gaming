#  Cloud Gaming in Azure

Table of contents

  1. [About](#about)
  2. [Disclaimer](#disclaimer)
  3. [Known issue](#known-issue)
  4. [Usage](#usage)
  5. [Delete the Azure infrastructure](#delete-the-azure-infrastructure)
  6. [Futur](#futur)

## About

This project automates the set-up process for cloud gaming on a Nvidia Tesla M60 GPU on Azure Standard NV6 VM.
The development of this project is heavily inspired by this [excellent guide](https://link.medium.com/wXD4ZJWb5T).

* Cloud gaming technology used
  * [x] [Parsec](https://parsecgaming.com/)
  * [x] [Steam In-Home streaming](https://support.steampowered.com/kb_cat.php?id=112) using [ZeroTier](https://www.zerotier.com/) VPN
  * [ ] [NVIDIA GameStream](https://support-shield.nvidia.com/gamestream-user-guide) using [Moonlight](https://moonlight-stream.org/)

* Game launcher installed
  * [ ] Battle.net (soon)
  * [x] Epic Games Launcher
  * [ ] GOG Galaxy (soon)
  * [ ] Origin (soon)
  * [x] Steam
  * [ ] UPlay (soon)

* Software installed
  * [x] [7zip](https://www.7-zip.org/)
  * [x] [Nvidia Tesla](https://www.nvidia.com/Download/processFind.aspx?psid=75&pfid=783&osid=57&lid=1&whql=1&lang=en-us) drivers for Windows 10
  * [x] [Parsec](https://parsecgaming.com/) for game streaming
  * [x] [VB-CABLE](https://www.vb-audio.com/Cable/) driver
  * [x] [ZeroTier One](https://www.zerotier.com/) for VPN

## Disclaimer

**This software comes with no warranty of any kind**. USE AT YOUR OWN RISK! This a personal project and is NOT endorsed by Microsoft. If you encounter an issue, please submit it on GitHub.

## Known issue

The only issue so far is about Steam In-Home streaming. Due to a bug, you cannot return to the Windows Desktop during your game session using ALT+TAB.

A workaround could be to press ALT+ENTER to switch from fullscreen to window mode, and then return to the Desktop.

## Usage

### Create the infrastructure in Azure

* The only requirement is to have AZ CLI installed. You can use the [Azure Cloud Shell](https://shell.azure.com/)
* Do not forget to update the options values of the below example.
* At the end, you will be prompted to choose your Windows **admin password**

```bash
rm -rf ~/azure-gaming
git clone https://github.com/nVentiveUX/azure-gaming.git
cd ~/azure-gaming

# Yvesub example
./create_vmss.sh \
    --subscription="8d8af6bf-9138-4d9d-a2e6-5bff1e3044c5" \
    --location="westeurope" \
    --rg-vnet="rg-net-shared-001" \
    --vnet-name="vnt-shared-001" \
    --subnet-name="snt-gaming-001" \
    --subnet="10.1.0.16/28" \
    --rg-vm="rg-inf-gaming-001" \
    --vm-name="vm-gaming-001" \
    --lb-name="lb-gaming-001"
```

### Configure the Virtual Machine

* Connect using RDP. *Click on the Windows key in the bottom-left corner, type "mstsc", and open on the app.*
* From powershell admin prompt, run the 1st script

```ps
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$path = "C:\azure"
New-Item -ItemType Directory -Force -Path $path | Out-Null
(New-Object System.Net.WebClient).DownloadFile("https://github.com/nVentiveUX/azure-gaming/raw/master/setup1.ps1", "$path\setup1.ps1")
powershell -ExecutionPolicy Unrestricted -File "$path\setup1.ps1"
```

* Reboot
* From powershell admin prompt run the 2nd script

```ps
$path = "C:\azure"
New-Item -ItemType Directory -Force -Path $path | Out-Null
(New-Object System.Net.WebClient).DownloadFile("https://github.com/nVentiveUX/azure-gaming/raw/master/setup2.ps1", "$path\setup2.ps1")
powershell -ExecutionPolicy Unrestricted -File "$path\setup2.ps1"
```

### Configure Parsec

On you local machine
* Install the [Parsec](https://parsecgaming.com/downloads) client
* Sign In

On the VM
* Sign In to Parsec using the same account and **Enable Hosting**
* Close the remote desktop connection using the shortcut ```disconnect.lnk``` on the **Desktop**.
* Try to connect into the VM thought your local installation of Parsec
* On the VM, tick **Run when my computer starts** from the minimized icon into the task bar
* Reboot the VM... and you're done.

### Configure ZeroTier VPN

On you local machine
* Create a dedicated [ZeroTier network](https://my.zerotier.com/network)
  * [x] Certificate (Private Network) (_Access Control_)
  * [x] Enable Broadcast (ff:ff:ff:ff:ff:ff)
  * [x] Auto-Assign from Range (_IPv4 Auto-Assign_)
  * [ ] All IPv6 stuff
* Install the client [ZeroTier One](https://download.zerotier.com/dist/ZeroTier%20One.msi), Sign In and  **Join the Network**
* Tick Preferences.../**Launch ZeroTier On StartUp** from the minimized icon into the task bar

On the VM
* Open ZeroTier One, Sign In and **Join the Network**
* Tick Preferences.../**Launch ZeroTier On StartUp** from the minimized icon into the task bar

### Configure Steam In-Home streaming

On you local machine
* Open Steam and Sign In to configure the client
* _In-Home Streaming_
  * [x] Enable streaming
  * [x] Beautiful
* _In-Home Streaming_ > Advanced Client Options, and Check only the following:
  * [x] - Limit bandwidth to 30 Mbits/s (do NOT set unlimited, it does not work)
  * [x] - Limit resolution to > Display resolution
  * [x] - Enable hardware decoding
  * [ ] - Display performance information (Press F6 to display it in-game)

On the VM
* Open Steam and Sign In to configure the client
* _In-Home Streaming_
  * [x] Enable streaming
* _In-Home Streaming_ > Advanced Host Options, and Check only the following:
  * [x] _Enable hardware encoding_
  * [x] _Prioritize network traffic_
  * [ ] _Prefer NvFBC capture methode_ See [Explanation: NvFBC, NvIFR, NvENC](https://steamcommunity.com/groups/homestream/discussions/0/451850849186356998/#c451850849191050105) for more info

Now, steam should see the Streaming VM. Try to launch a game !

## Delete the Azure infrastructure

```bash
az group delete --name rg-inf-gaming-001
```

## Futur

* [ ] Update VM SKU to [Standard_NV6s_v2](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/sizes-gpu#nvv2-series-preview) (awaiting end of preview)
* [ ] Update OS to Windows 10 1809 (```rs5-pron```), as soon as Nvidia drivers will be supported on this version. (See [Supported operating systems and drivers](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup#supported-operating-systems-and-drivers) for more details. We are using ```rs4-pron``` today.
```bash
az vm image list --publisher MicrosoftWindowsDesktop --all -otable

Offer       Publisher                Sku       Urn                                                       Version
----------  -----------------------  --------  --------------------------------------------------------  ------------
Windows-10  MicrosoftWindowsDesktop  RS3-Pro   MicrosoftWindowsDesktop:Windows-10:RS3-Pro:16299.904.65   16299.904.65
Windows-10  MicrosoftWindowsDesktop  RS3-ProN  MicrosoftWindowsDesktop:Windows-10:RS3-ProN:16299.904.65  16299.904.65
Windows-10  MicrosoftWindowsDesktop  rs4-pro   MicrosoftWindowsDesktop:Windows-10:rs4-pro:17134.523.65   17134.523.65
Windows-10  MicrosoftWindowsDesktop  rs4-pron  MicrosoftWindowsDesktop:Windows-10:rs4-pron:17134.523.65  17134.523.65
Windows-10  MicrosoftWindowsDesktop  rs5-evd   MicrosoftWindowsDesktop:Windows-10:rs5-evd:17763.253.67   17763.253.67
Windows-10  MicrosoftWindowsDesktop  rs5-pro   MicrosoftWindowsDesktop:Windows-10:rs5-pro:17763.253.65   17763.253.65
Windows-10  MicrosoftWindowsDesktop  rs5-pron  MicrosoftWindowsDesktop:Windows-10:rs5-pron:17763.253.67  17763.253.67
```

## News

* [x] Download and install the latest [NVIDIA Capture SDK](https://developer.nvidia.com/capture-sdk) (formerly GRID SDK)

