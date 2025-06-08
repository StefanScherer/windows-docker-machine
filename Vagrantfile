# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.8.4"

Vagrant.configure("2") do |config|
  config.vm.communicator = "winrm"

  config.vm.synced_folder ".", "/vagrant", disabled: true
  home = ENV['HOME'].gsub('\\', '/')
  config.vm.synced_folder home, home

  config.vm.define "2016", autostart: false do |cfg|
    cfg.vm.box     = "windows_2016_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2016"
  end

  config.vm.define "2016-box", autostart: false do |cfg|
    cfg.vm.box     = "StefanScherer/windows_2016_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2016-box"
    cfg.vm.provider "virtualbox" do |v, override|
      override.vm.network :private_network, ip: "192.168.59.50", gateway: "192.168.56.1"
    end
  end

  config.vm.define "1709", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_1709_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 1709"
  end

  config.vm.define "1803", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_1803_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 1803"
  end

  config.vm.define "1809", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_1809_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 1809"
  end

  config.vm.define "1903", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_1903_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 1903"
  end

  config.vm.define "2019", autostart: false do |cfg|
    cfg.vm.box     = "windows_2019_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2019"
  end

  config.vm.define "2019-box", autostart: false do |cfg|
    cfg.vm.box     = "StefanScherer/windows_2019_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2019-box"
    cfg.vm.provider "virtualbox" do |v, override|
      override.vm.network :private_network, ip: "192.168.59.51", gateway: "192.168.56.1"
    end
  end

  config.vm.define "2022", autostart: false do |cfg|
    cfg.vm.box     = "windows_2022_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2022"
  end

  config.vm.define "2022-box", autostart: false do |cfg|
    cfg.vm.box     = "StefanScherer/windows_2022_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2022-box"
    cfg.vm.provider "virtualbox" do |v, override|
      override.vm.network :private_network, ip: "192.168.59.52", gateway: "192.168.56.1"
    end
  end

  config.vm.define "2025", autostart: false do |cfg|
    cfg.vm.box     = "windows_2025_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName 2025"
  end

  config.vm.define "insider", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_insider_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName insider"
  end

  config.vm.define "lcow", autostart: false do |cfg|
    cfg.vm.box     = "windows_server_1903_docker"
    cfg.vm.provision "shell", path: "scripts/create-machine.ps1", args: "-machineHome #{home} -machineName lcow -enableLCOW"
    ["vmware_fusion", "vmware_workstation"].each do |provider|
      config.vm.provider provider do |v, override|
        v.memory = 5120
      end
    end
  end

  ["vmware_fusion", "vmware_workstation"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = false
      v.memory = 2048
      v.cpus = 2
      v.enable_vmrun_ip_lookup = false
      v.linked_clone = true
      v.vmx["vhv.enable"] = "TRUE"
      v.ssh_info_public = true
    end
  end

  config.vm.provider "virtualbox" do |v, override|
    v.gui = false
    v.memory = 2048
    v.cpus = 2
    v.linked_clone = true
    # Enable Nested Hardware Virtualisation - requires VirtualBox 6
    v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
    # Use the recommended paravirtualization interface for windows (hyperv) - requires VirtualBox 6
    v.customize ["modifyvm", :id, "--paravirtprovider", "hyperv"]
  end

  config.vm.provider "hyperv" do |v|
    v.cpus = 2
    v.maxmemory = 2048
    v.differencing_disk = true
  end
end
