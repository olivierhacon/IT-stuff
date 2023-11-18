# Configuring an NVIDIA GeForce RTX 20, 30, 40 Series as an eGPU (Razer Core X) to be the primary GPU on Linux Fedora 39 under Wayland desktop with Secure Boot enabled

## Requirements

You have already authorized your eGPU (if necessary) and are able to connect to it.  
Using this command, your device should be listed:

```bash
lspci -k | grep -A 2 -E "(VGA|3D)"
```

## Installing NVIDIA driver

After trying to install the NVIDIA drivers using RPM Fusion without success (lots of problems with secure boot), I decided to manually install the official NVIDIA drivers.

1. Install Development Tools and Kernel Headers

```bash
sudo dnf install kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig
```
2. Download NVIDIA Driver from https://www.nvidia.com/Download/Find.aspx?lang=en-us
3. Disabling Nouveau Drivers in Fedora

```bash
#Blacklist Nouveau Driver:
echo -e "blacklist nouveau\noptions nouveau modeset=0" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
#Regenerate the Initial Ramdisk (initramfs)
sudo dracut --force
#Update the GRUB Configuration
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
#Update the GRUB Configuration (UEFI)
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
#Force Fedora booting into a text-based, multi-user mode instead of a graphical user interface (GUI)
sudo systemctl set-default multi-user.target
```
Reboot
    
4. Verify that Nouveau is Disabled

```bash
lsmod | grep nouveau #If there's NO output, then Nouveau has been successfully disabled
```

5. Install the NVIDIA Drivers

```bash
cd ~/Downloads
chmod +x NVIDIA-Linux-*.run
sudo ./NVIDIA-Linux-*.run
```

During the installation, you will need to respond to some prompts.  
The prompt regarding the generation of signing keys for the NVIDIA Kernel Module is mandatory for systems using secure boot (if you do not already have a key pair suitable for module signing use).  
Follow the steps to generate new keys that can be used for module signing. Upon completion an X.509 certificate containing the public key will be installed to:  

```bash
/usr/share/nvidia/nvidia-modsign-crt-XXXXXX.der
```
Make a note of this location, and of the certificate's SHA1 fingerprint.

> Please make sure that appropriate precautions are taken to ensure that the private key cannot be stolen.

Continue installation to completion.

6. Import the key using:

```bash
mokutil --import /usr/share/nvidia/nvidia-modsign-crt-XXXXXX.der
#The command will ask for a password to protect the key. Keep in mind that the QWERTY layout will be used
```

Enable GUI and reboot:

```bash
sudo systemctl set-default graphical.target
reboot
```

When booting, a splash screen titled 'Perform MOK Management' appears.

1. Select 'Enroll MOK'.
2. 'View key 0' to check key's information (SHA1 fingerprint, etc.), then press any key to return to the previous menu.
3. Select 'Continue'
4. 'Enroll the key(s)?' Yes and enter the password you chose during the import with mokutil.

## Configuring your eGPU as primary with 'all-ways-egpu' script

Use the script provided at https://github.com/ewagner12/all-ways-egpu. Folow the installation and usage instructions. On my system, the Method 1 was the only that worked.

# Some useful commands:

```bash
#List the VGA and 3D graphics controllers in your system
lspci -k | grep -A 2 -E "(VGA|3D)"
#Getting detailed information about NVIDIA GPUs
nvidia-smi
#Finding out what graphics card is being used for rendering graphics in your system,
glxinfo | grep "OpenGL renderer"
```

# References

- https://us.download.nvidia.com/XFree86/Linux-x86_64/535.129.03/README/installdriver.html
- https://www.tecmint.com/install-nvidia-drivers-in-linux/
- https://egpu.io/forums/thunderbolt-linux-setup/all-ways-egpu-script-for-wayland-linux-desktops/
- https://github.com/ewagner12/all-ways-egpu
