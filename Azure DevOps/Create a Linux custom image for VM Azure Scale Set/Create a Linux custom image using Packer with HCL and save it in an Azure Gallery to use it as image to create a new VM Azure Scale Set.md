# Introduction 
Create a Linux custom image using Packer with HCL and save it in an Azure Gallery to use it as image to create a new VM Azure Scale Set

## 1.	Prerequisites

### 1.1 Virtual Machine Scale Set

- An ssh public key

```bash
#To list existing keys
az sshkey list --resource-group "<YOUR-RESOURCE-GROUP>"
#To create an new keys pair in Azure
az sshkey create --name "mySSHKey" --resource-group "<YOUR-RESOURCE-GROUP>"
```
- VNET and SUBNET ID's

```bash
#To get vnet and subnet (in this case) IDs
az network vnet show --name <YOUR-VNET-NAME> --resource-group <YOUR-RESOURCE-GROUP> --query id --output tsv
az network vnet subnet show --name private-devops-sbx-sub --vnet-name <YOUR-VNET-NAME> --resource-group <YOUR-RESOURCE-GROUP> --query id --output tsv
```
### 1.2 Custom Image (Packer)

- A SP (service principal) with contributor rights (or some subset thereof) to the entire subscription account client ID and client Secret.
- Install packer
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install packer
packer -v
```
- Connect to Azure and get some informations required by the Packer plugin Azure ARM builder

```bash
#to get subscription_id and tenant_id
az account show --query "{subscriptionId:id, tenantId:tenantId}"
```

```bash
#to find the best match for a linux image from Canonical (Ubuntu) publisher and get image_offer, image_publisher and image_sku
az vm image list --all --location westeurope --publisher Canonical --output table --query "[].{Offer:offer, Sku:sku}" | sort -u
```
## 2.	Custom Image Creation

- create a Packer Configuration File: Create a new file with a .hcl extension
```bash
touch azvmss_cust_img-pkr.hcl
```
### Example:

```bash
source "azure-arm" "custimgtst" {

  client_id                         = "<YOUR-CLIENT-ID>"
  client_secret                     = "<YOUR-CLIENT-SECRET>"
  subscription_id                   = "<YOUR-SUBSCRIPTION-ID>"
  tenant_id                         = "<YOUR-TENANT-ID>"
  #If the rights of the SPN are too limited or restricted use the build_resource_group_name parameter - Specify an existing resource group to run the build in (location in combination with build_resource_group_name is not allowed).
  build_resource_group_name         = "<YOUR-RESOURCE-GROUP>"
  managed_image_name                = "azvmss_packer_image"
  managed_image_resource_group_name = "<YOUR-RESOURCE-GROUP>"
  os_type                           = "Linux"
  image_publisher                   = "canonical"
  image_offer                       = "0001-com-ubuntu-server-jammy"
  image_sku                         = "22_04-lts"
  vm_size                           = "Standard_B2s"
}

build {
  sources = ["source.azure-arm.custimgtst"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = ["apt update", "apt upgrade -y", "apt install -y wget apt-transport-https software-properties-common unzip dotnet-sdk-6.0", "wget -q \"https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb\"", "dpkg -i packages-microsoft-prod.deb", "rm packages-microsoft-prod.deb", "add-apt-repository ppa:git-core/ppa", "apt update", "apt install -y powershell git"
, "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"]
    inline_shebang  = "/bin/sh -x"
  }

}
```
- Run the build (after few minutes the image will be available in the RG)
```bash
sudo packer build -force azvmss_wksp/azvmss_cust_img.pkr.hcl
```

- Create a (compute) image gallery
```bash
az sig create --resource-group <YOUR-RESOURCE-GROUP> --gallery-name azvmss_cust_img_gal
```

- Create an image definition (create a logical grouping for images requested to publish our image in the next command)
```bash
az sig image-definition create --resource-group <YOUR-RESOURCE-GROUP> --gallery-name azvmss_cust_img_gal --gallery-image-definition azvmss_cust_img_gal_def --publisher canonical --offer ubuntu-server-jammy --sku 22_04-lts --os-type Linux
```

- Create an image version and publish the image in the image gallery
```bash
az sig image-version create --resource-group <RESOURCE-GROUP-NAME> --gallery-name <GALLERY-NAME> --gallery-image-definition <IMAGE-DEFINITION-NAME> --gallery-image-version 1.0.0 --managed-image "/subscriptions/<SUBSCRIPTION-ID>/resourceGroups/<RESOURCE-GROUP-NAME>/providers/Microsoft.Compute/images/<IMAGE-NAME>"
```

- Create the Virtual Machine Scale Set using the custom image we created (because the net resources are in another RG, we only need to specify fully-qualified ID for the subnet, without --vnet-name that doesn't support IDs, only name)
```bash
az vmss create --name <VMSS-NAME> --resource-group <RESOURCE-GROUP-NAME> --image "/subscriptions/<SUBSCRIPTION-ID>/resourceGroups/<RESOURCE-GROUP-NAME>/providers/Microsoft.Compute/galleries/<GALLERY-NAME>/images/<IMAGE-DEFINITION-NAME>" --authentication-type SSH --ssh-key-value <PATH-TO-YOUR-SSH-KEY> --instance-count 2 --disable-overprovision --upgrade-policy-mode manual --single-placement-group false --platform-fault-domain-count 1 --subnet "/subscriptions/<SUBSCRIPTION-ID>/resourceGroups/<NETWORK-RESOURCE-GROUP>/providers/Microsoft.Network/virtualNetworks/<VNET-NAME>/subnets/<SUBNET-NAME>" --public-ip-address "" --load-balancer ""
```
### References

- https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops
- https://learn.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer
- https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli
- https://developer.hashicorp.com/packer/plugins/builders/azure/arm
- https://learn.microsoft.com/en-us/cli/azure/vmss?view=azure-cli-latest#az-vmss-create
- https://learn.microsoft.com/en-us/azure/virtual-machine-scale-sets/tutorial-use-custom-image-cli
- https://learn.microsoft.com/en-us/azure/developer/terraform/create-vm-scaleset-network-disks-using-packer-hcl
