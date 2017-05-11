stop-service docker
$wc = New-Object net.webclient
$wc.Downloadfile("https://master.dockerproject.org/windows/amd64/dockerd.exe", "$env:ProgramFiles\docker\dockerd.exe")
$wc.Downloadfile("https://master.dockerproject.org/windows/amd64/docker.exe", "$env:ProgramFiles\docker\docker.exe")

if (Test-Path "$($env:ProgramData)\docker\image\Windows filter storage driver") {
  ren "$($env:ProgramData)\docker\image\Windows filter storage driver" "$($env:ProgramData)\docker\image\windowsfilter"
}

start-service docker
