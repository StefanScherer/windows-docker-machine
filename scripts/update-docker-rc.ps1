Write-Host "Stopping docker service"
Stop-Service docker
$version = "17.06.0-ce-rc3"

Write-Host "Downloading docker-$version.zip"
$wc = New-Object net.webclient
$wc.DownloadFile("https://download.docker.com/win/static/test/x86_64/docker-$version-x86_64.zip", "$env:TEMP\docker-$version.zip")
Write-Host "Extracting docker-$version.zip"
Expand-Archive -Path "$env:TEMP\docker-$version.zip" -DestinationPath $env:ProgramFiles -Force
Remove-Item "$env:TEMP\docker-$version.zip"

Write-Host "Activating experimental features"
$daemonJson = "$env:ProgramData\docker\config\daemon.json"
$config = @{}
if (Test-Path $daemonJson) {
  $config = (Get-Content $daemonJson) -join "`n" | ConvertFrom-Json
}
$config = $config | Add-Member(@{ experimental = $true }) -Force -PassThru
$config | ConvertTo-Json | Set-Content $daemonJson -Encoding Ascii

Write-Host "Starting docker service"
Start-Service docker
