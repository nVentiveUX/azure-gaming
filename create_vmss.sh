#!/bin/bash

set -eu -o pipefail

PROGNAME="$(basename "$0")"

# Parse arguments
ARGS=$(getopt \
    --options s:l:g:v:s:n:r:m:b \
    --longoptions subscription:,location:,rg-vnet:,vnet-name:,subnet-name:,subnet:,rg-vm:,vm-name:,lb-name: \
    -n "${PROGNAME}" -- "$@")
eval set -- "${ARGS}"
unset ARGS

AZ_SUBSCRIPTION_ID=""
AZ_LOCATION=""
AZ_VNET_RG=""
AZ_VNET=""
AZ_VNET_SUBNET_NAME=""
AZ_VNET_SUBNET=""
AZ_VM_RG=""
AZ_VM=""
AZ_LB=""

while true; do
  case "$1" in
    '-s'|'--subscription')
        AZ_SUBSCRIPTION_ID="$2"
        shift 2
        continue
    ;;
    '-l'|'--location')
        AZ_LOCATION="$2"
        shift 2
        continue
    ;;
    '-g'|'--rg-vnet')
        AZ_VNET_RG="$2"
        shift 2
        continue
    ;;
    '-v'|'--vnet-name')
        AZ_VNET="$2"
        shift 2
        continue
    ;;
    '-s'|'--subnet-name')
        AZ_VNET_SUBNET_NAME="$2"
        shift 2
        continue
    ;;
    '-n'|'--subnet')
        AZ_VNET_SUBNET="$2"
        shift 2
        continue
    ;;
    '-r'|'--rg-vm')
        AZ_VM_RG="$2"
        shift 2
        continue
    ;;
    '-m'|'--vm-name')
        AZ_VM="$2"
        shift 2
        continue
    ;;
    '-b'|'--lb-name')
        AZ_LB="$2"
        shift 2
        continue
    ;;
    '--')
        shift
        break
    ;;
    *)
        usage
        exit 1
    ;;
  esac
done

# Show usage
usage() {
    printf "usage: %s --subscription=<name> --location=<name> --rg-vnet=<name> --vnet-name=<name> --subnet-name=<name> --subnet=<name> --rg-vm=<name> --vm-name=<name> --lb-name=<name>\\n" "${PROGNAME}"
}

# Pre-checks
if [[ -z $AZ_SUBSCRIPTION_ID ]]; then
    echo "Error: --subscription is required !"
    usage
    exit 1
fi

if [[ -z $AZ_LOCATION ]]; then
    echo "Error: --location is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VNET_RG ]]; then
    echo "Error: --rg-vnet is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VNET ]]; then
    echo "Error: --vnet-name is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VNET_SUBNET_NAME ]]; then
    echo "Error: --subnet-name is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VNET_SUBNET ]]; then
    echo "Error: --subnet is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VM_RG ]]; then
    echo "Error: --rg-vm is required !"
    usage
    exit 1
fi

if [[ -z $AZ_VM ]]; then
    echo "Error: --vm-name is required !"
    usage
    exit 1
fi

if [[ -z $AZ_LB ]]; then
    echo "Error: --lb-name is required !"
    usage
    exit 1
fi

printf "Switch to ${AZ_SUBSCRIPTION_ID} subscription..."
az account set --subscription "${AZ_SUBSCRIPTION_ID}" --output none
printf "Done.\\n"

if ! az network vnet show --resource-group ${AZ_VNET_RG} --name ${AZ_VNET} --output none; then
    printf "VNET ${AZ_VNET} is missing. Please create it before...\\n"
    exit 1
else
    printf "Create a new ${AZ_VNET_SUBNET} subnet named ${AZ_VNET_SUBNET_NAME}..."
    az network vnet subnet create \
        --resource-group "${AZ_VNET_RG}" \
        --vnet-name "${AZ_VNET}" \
        --name "${AZ_VNET_SUBNET_NAME}" \
        --address-prefix "${AZ_VNET_SUBNET}" \
        --output none
    printf "Done.\\n"
fi

printf "Create ${AZ_VM_RG} resource group..."
az group create \
    --location "${AZ_LOCATION}" \
    --name "${AZ_VM_RG}" \
    --output none
printf "Done.\\n"

printf "Create ${AZ_LB}.${AZ_LOCATION}.cloudapp.azure.com basic public IP address..."
az network public-ip create \
    --name "${AZ_LB}-public-ip" \
    --resource-group "${AZ_VM_RG}" \
    --allocation-method "dynamic" \
    --sku "Basic" \
    --version "IPv4" \
    --dns-name "${AZ_LB}" \
    --output none
printf "Done.\\n"

printf "Create ${AZ_LB} basic load balancer..."
az network lb create \
    --name "${AZ_LB}" \
    --resource-group "${AZ_VM_RG}" \
    --public-ip-address "${AZ_LB}-public-ip" \
    --frontend-ip-name "${AZ_LB}-public-ip" \
    --backend-pool-name "VMSSBackend" \
    --sku "Basic" \
    --output none
printf "Done.\\n"

printf "Create NAT pool rules for RDP connection..."
az network lb inbound-nat-pool create \
    --name "TCP443to3389" \
    --resource-group "${AZ_VM_RG}" \
    --lb-name "${AZ_LB}" \
    --frontend-port-range-start "50000" \
    --frontend-port-range-end "50001" \
    --backend-port "3389" \
    --frontend-ip-name "${AZ_LB}-public-ip" \
    --protocol "tcp" \
    --output none
printf "Done.\\n"

printf "Create NSG ${AZ_VM}-nsg..."
az network nsg create \
    --name "${AZ_VM}-nsg" \
    --resource-group "${AZ_VM_RG}" \
    --output none
printf "Done.\\n"

printf "Create NSG rule to allow RDP..."
az network nsg rule create \
    --name "Allow_RDP" \
    --nsg-name "${AZ_VM}-nsg" \
    --resource-group "${AZ_VM_RG}" \
    --priority "1000" \
    --direction "Inbound" \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "VirtualNetwork" \
    --destination-port-ranges "3389" \
    --access "Allow" \
    --protocol "tcp" \
    --description "Allow RDP traffic from Any" \
    --output none
printf "Done.\\n"

printf "Create ${AZ_VM} Azure Virtual Machine Scale Set...\\n"
az vmss create \
    --name "${AZ_VM}" \
    --resource-group "${AZ_VM_RG}" \
    --image "MicrosoftWindowsDesktop:Windows-10:rs5-pron:17763.253.67" \
    --vm-sku "Standard_NV6" \
    --storage-sku "StandardSSD_LRS" \
    --instance-count "1" \
    --eviction-policy "delete" \
    --priority "Low" \
    --upgrade-policy-mode "Automatic" \
    --subnet "/subscriptions/${AZ_SUBSCRIPTION_ID}/resourceGroups/${AZ_VNET_RG}/providers/Microsoft.Network/virtualNetworks/${AZ_VNET}/subnets/${AZ_VNET_SUBNET_NAME}" \
    --nsg "${AZ_VM}-nsg" \
    --public-ip-address "" \
    --load-balancer "${AZ_LB}" \
    --lb-nat-pool-name "TCP443to3389" \
    --output none
printf "Done.\\n\\n"

printf "Please use Microsoft Remote Desktop app connect to ${AZ_LB}.${AZ_LOCATION}.cloudapp.azure.com:5000 or :5001.\\n"
printf "You can run this script from powershell admin prompt to configure the VM:\\n"
printf "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/nVentiveUX/azure-gaming/master/utils.ps1'))\\n"
