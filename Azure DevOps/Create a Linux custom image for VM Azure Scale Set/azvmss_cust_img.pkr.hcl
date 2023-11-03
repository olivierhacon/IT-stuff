source "azure-arm" "custimgtst" {

  client_id                         = "<YOUR_CLIENT_ID>"
  client_secret                     = "<YOUR_CLIENT_SECRET>"
  subscription_id                   = "<YOUR_SUBSCRIPTION_ID>"
  tenant_id                         = "<YOUR_TENANT_ID>"
  build_resource_group_name         = "<YOUR_RESOURCE_GROUP>"
  managed_image_name                = "azvmss_packer_image"
  managed_image_resource_group_name = "<YOUR_RESOURCE_GROUP>"
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
    inline          = [
      "apt update",
      "apt upgrade -y",
      "apt install -y wget apt-transport-https software-properties-common unzip dotnet-sdk-6.0",
      "wget -q \"https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb\"",
      "dpkg -i packages-microsoft-prod.deb",
      "rm packages-microsoft-prod.deb",
      "add-apt-repository ppa:git-core/ppa",
      "apt update",
      "apt install -y powershell git",
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
    ]
    inline_shebang  = "/bin/sh -x"
  }

}
