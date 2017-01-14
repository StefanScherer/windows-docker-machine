param ([String] $machineHome, [String] $machineName, [String] $machineIp)

if (!(Test-Path $env:USERPROFILE\.docker)) {
  mkdir $env:USERPROFILE\.docker
}

$ips = ((Get-NetIPAddress -AddressFamily IPv4).IPAddress) -Join ','

if (!$machineIp) {
  $machineIp=(Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object -FilterScript { $_.InterfaceAlias -Ne "vEthernet (HNS Internal NIC)" -And $_.IPAddress -Ne "127.0.0.1" } `
    ).IPAddress
}

$homeDir = $machineHome
if ($machineHome.startsWith('/')) {
  $homeDir = "C:$machineHome" # /Users/stefan from Mac -> C:/Users/stefan
}

docker run --rm `
  -e SERVER_NAME=$(hostname) `
  -e IP_ADDRESSES=$ips `
  -e MACHINE_HOME=$machineHome `
  -e MACHINE_NAME=$machineName `
  -e MACHINE_IP=$machineIp `
  -v "$env:USERPROFILE\.docker:C:\Users\ContainerAdministrator\.docker" `
  -v "$homeDir\.docker:C:\machine\.docker" `
  -v "C:\ProgramData\docker:C:\ProgramData\docker" `
  stefanscherer/dockertls-windows

stop-service docker
dockerd --unregister-service
dockerd --register-service
start-service docker

& netsh advfirewall firewall add rule name="Docker TLS" dir=in action=allow protocol=TCP localport=2376
