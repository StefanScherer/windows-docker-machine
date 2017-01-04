# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.8.4"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box          = "windows_2016_docker"
  config.vm.communicator = "winrm"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ENV['HOME'], ENV['HOME']

  config.vm.provision "shell", path: "scripts/create-machine.ps1", privileged: false, args: "-machineHome #{ENV['HOME']} -machineName windows"

  ["vmware_fusion", "vmware_workstation"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = false
      v.vmx["memsize"] = "2048"
      v.vmx["numvcpus"] = "2"
      v.enable_vmrun_ip_lookup = false
      v.linked_clone = true
    end
  end
end
