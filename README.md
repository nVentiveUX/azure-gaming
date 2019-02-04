#  Cloud Gaming in Azure

## About

Effortlessly stream the latest games on Azure using [Parsec](https://parsecgaming.com/). This project automates the set-up process for cloud gaming on a Nvidia Tesla M60 GPU on Azure. The development of this project is heavily inspired by this [excellent guide](https://blog.parsecgaming.com/cloud-gaming-on-an-azure-server-using-parsec-2edcd24636f8).

## Disclaimer

**This software comes with no warranty of any kind**. USE AT YOUR OWN RISK! This a personal project and is NOT endorsed by Microsoft. If you encounter an issue, please submit it on GitHub.

## Usage
### Create the infrastructure in Azure

* The only requirement is to have AZ CLI installed. You can use the [Azure Cloud Shell](https://shell.azure.com/).
* Do not forget to update the options values of the script ```create_vmss.sh```
* At the end, you will be prompted to choose your Windows **admin password**.

```bash
rm -rf ~/azure-gaming
git clone https://github.com/nVentiveUX/azure-gaming.git
cd ~/azure-gaming

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
* From powershell admin prompt, disable UAC and reboot.

```ps
New-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system" -Name EnableLUA -PropertyType DWord -Value 0 -Force
Write-host -ForegroundColor Yellow "Rebooting now..."; Start-Sleep -s 2; Restart-Computer
```

* From powershell admin prompt, run the 1st script

```ps
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("https://github.com/nVentiveUX/azure-gaming/raw/master/setup1.ps1", "C:\setup1.ps1")
powershell -ExecutionPolicy Unrestricted -File "C:\setup1.ps1"
```

* Reboot
* From powershell admin prompt run the 2nd script

```ps
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
(New-Object System.Net.WebClient).DownloadFile("https://github.com/nVentiveUX/azure-gaming/raw/master/setup2.ps1", "C:\setup2.ps1")
powershell -ExecutionPolicy Unrestricted -File "C:\setup2.ps1"
```

* Sign-In to Parsec and **enable Hosting**.
* Close the remote desktop connection using the shortcut ```C:\disconnect.lnk```
* Try to connect into the VM thought your local installation of Parsec
* On the VM, tick **Run when my computer starts** from the minimized icon into the task bar.
* Reboot the VM... and you're done.

## Delete the Azure infrastructure

```bash
az group delete --name rg-inf-gaming-001
```

