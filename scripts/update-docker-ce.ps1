$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$version = "17.05.0-ce"
if ($(docker --version).StartsWith("Docker version $version")) {
  Write-Host Already updated.
  exit 0;
}

Write-Host "Stopping docker service"
Stop-Service docker

Write-Host "Downloading docker-$version.zip"
$wc = New-Object net.webclient
$wc.DownloadFile("https://get.docker.com/builds/Windows/x86_64/docker-$version.zip", "$env:TEMP\docker-$version.zip")
Write-Host "Extracting docker-$version.zip"
Expand-Archive -Path "$env:TEMP\docker-$version.zip" -DestinationPath $env:ProgramFiles -Force
Remove-Item "$env:TEMP\docker-$version.zip"

Write-Host "Starting docker service"
Start-Service docker

docker version
