# Introduction

I am tempted to try again to go for getting the LFCS certification. I have worked with Linux on and off over the years and have no problem working with it. However, most of my knowledge is selfobtained and unguided. Also it is somewhat deprecated (like still using ifconfig and not ip...). So it could be fun to do it a little bit more structured.

The course is given (on Pluralsight) by Andrew Mallet, aka [theurbanpenguin](https://github.com/theurbanpenguin). In one of the first steps, [Vagrant](https://developer.hashicorp.com/vagrant) is used to setup some Ubuntu vms to run the demo's and practise on. However, because I am also running WSL 2, I ran into some complications.

# Getting Vagrant to work on Windows 11 with WSL2 (and thus, HyperV) installed
I first tried using virtualbox (the default for Vagrant). In and of itself, this works great and out of the box. However, it is slow, because it is running in emulation mode (because of HyperV). So, I wanted to use HyperV instead. My first attempt was to do everything from Windows directly. However, I found two problems with it:
- Because of the ACL changes that HyperV makes on the project folder ([capability sid](https://learn.microsoft.com/en-us/troubleshoot/windows-server/windows-security/sids-not-resolve-into-friendly-names)), this gives an error on the private key created by Vagrant and will ask you for a password.
- The only way for vagrant to sync files into the VM from Windows, appears to be using SMB. This feels a bit clunky. If file sync does not work, you also cannot use 'ansible_local' to configure the VM.

**_Note: This is not the only, nor maybe the best way. But it works and is simple, which is what I wanted_**

- Create a new external network bridge in HyperV (in my case aptly named: External Switch). VMs on the default ones are not accessible from WSL, which causes vagrant to hang on (example): _ubuntu2: SSH auth method: private key_
- Install Vagrant in Windows
- Install Vagrant in [WSL](https://developer.hashicorp.com/vagrant/docs/other/wsl)
- Add the following to your profile to set environment variables:
```bash
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/USERNAME/"
```
- You may also have to update your wsl.conf to include the following line:
```
options = "metadata,umask=77,fmask=11"
```
- Run WSL in an elevated terminal (this is apparently required for certain HyperV calls)
- Go to your project folder (where the VagrantFile is) and use "vagrant up" or whatever vagrant call you want to do

Providing you have setup DHCP outside of HyperV (like your ISP router) and you don't mind the vagrant VMs to use those IP addresses, this should work. 

Static ip addresses cannot be set from within HyperV. There are some workarounds using triggers, but I chose the easy way: Set a static MAC address (this does work) and make a reservation in DHCP

I updated the Vagrant file from [theurbanpenguin](https://github.com/theurbanpenguin/lfcs) to run on HyperV (with a static MAC):

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

#Place Vagrantfile in the directory you run vagrant from.
#This should also contain ubuntu.yml which configure VMs

# setting for all VMs
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2004"
  config.vm.synced_folder ".", "/vagrant"
  config.vm.provision "ansible_local", playbook: "ubuntu.yml"
  config.vm.network "private_network", bridge: "External Switch"
  config.vm.provider "hyperv" do |v|
	v.memory = 2048
	v.cpus = 2
  end

  # specific for ubuntu1
  config.vm.define "ubuntu1" do |ubuntu1|
    ubuntu1.vm.hostname = "ubuntu1"
	ubuntu1.vm.provider "hyperv" do |v|
		v.mac = "020000000001"
	  end
  end

  # specific for ubuntu2
  config.vm.define "ubuntu2" do |ubuntu2|
    ubuntu2.vm.hostname = "ubuntu2"
	ubuntu2.vm.provider "hyperv" do |v|
		v.mac = "020000000002"
	  end
  end
end
```