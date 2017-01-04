# Windows Docker Machine

This Vagrant environment creates a Docker Machine to work from your MacBook
with Windows containers.

Tested with Vagrant 1.9.1 and VMware Fusion Pro 8.5.3 on a MacBook Pro.

#### Before you begin

You need the Vagrant basebox preinstalled as it is not available at Atlas. To build it yourself follow these commands:

```bash
$ git clone https://github.com/StefanScherer/packer-windows
$ cd packer-windows
$ packer build --only=vmware-iso windows_2016_docker.json
$ vagrant box add windows_2016_docker windows_2016_docker_virtualbox.box
```

## Create the Docker Machine

Spin up the headless Vagrant box with Windows Server 2016 and Docker installed.
It will create the TLS certs and create a `windows` Docker machine for your
`docker-machine` binary on your Mac.

```bash
$ vagrant up
```

## List your new Docker machine

```bash
$ docker-machine ls
NAME      ACTIVE   DRIVER         STATE     URL                          SWARM   DOCKER    ERRORS
dev       -        virtualbox     Running   tcp://192.168.99.100:2376            v1.12.5   
linux     -        vmwarefusion   Running                                        Unknown
windows   *        generic        Running   tcp://192.168.254.135:2376           Unknown   
```

Currently there is [an issue](https://github.com/docker/machine/issues/3943) that the client API version of `docker-machine` is too old. But switch Docker environments works as shown below.

## Switch to Windows containers

```bash
$ eval $(docker-machine env windows)
```

## Switch back to Docker for Mac

```bash
$ eval $(docker-machine env -unset)
```

## Mounting volumes from your Mac

Just use `C:$(pwd)` to prepend a drive letter.

```bash
$ docker run -it -v C:$(pwd):C:$(pwd) microsoft/windowsservercore powershell
```

Yes, this mounts the current directory through the Windows 2016 VM into the Windows Container.
