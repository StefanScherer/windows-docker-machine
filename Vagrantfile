# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.require_version ">= 1.8.4"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box          = "StefanScherer/windows_2016_docker"
  config.vm.communicator = "winrm"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder ENV['HOME'], ENV['HOME']

  config.vm.provision "shell", path: "scripts/create-machine.ps1", privileged: false, args: "-machineHome #{ENV['HOME']} -machineName windows"

  # Add the docker-machine subnet 192.168.99.* only for VirtualBox
  begin
    OptionParser.new do |opts|
      opts.on("--provider PROVIDER", String, "") do |provider|
        if provider == 'virtualbox'
          config.vm.network :private_network, ip: "192.168.99.90", gateway: "192.168.99.1"
        end
      end
    end.parse!
  rescue OptionParser::InvalidOption => e
  end

  ["vmware_fusion", "vmware_workstation"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = false
      v.memory = 2048
      v.cpus = 2
      v.enable_vmrun_ip_lookup = false
      v.linked_clone = true
    end
  end

  config.vm.provider "virtualbox" do |v|
    v.gui = false
    v.memory = 2048
    v.cpus = 2
    v.linked_clone = true
  end
end
