$ip=(Get-NetIPAddress -AddressFamily IPv4 `
   | Where-Object -FilterScript { $_.InterfaceAlias -Eq "vEthernet (HNS Internal NIC)" } `
   ).IPAddress

docker kill portainer
docker rm -vf portainer

if (!(Test-Path C:\portainerdata)) {
  mkdir C:\portainerdata
}

if (Test-Path $env:USERPROFILE\.docker\ca.pem) {
  docker run -d -p 8000:9000 `
    -v $env:USERPROFILE\.docker:C:\certs `
    -v C:\portainerdata:C:\data `
    --name portainer portainer/portainer:multiarch `
    -H tcp://$($ip):2376 --tlsverify
} else {
  docker run -d -p 8000:9000 `
  -v C:\portainerdata:C:\data `
  --name portainer portainer/portainer:multiarch -H tcp://$($ip):2375
}
