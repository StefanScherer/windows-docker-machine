param ([String] $machineHome, [String] $machineName, [String] $machineIp, [Switch] $enableLCOW, [Switch] $experimental)

$ErrorActionPreference = 'Stop';

if (!(Test-Path $env:USERPROFILE\.docker)) {
  mkdir $env:USERPROFILE\.docker
}

$ipAddresses = ((Get-NetIPAddress -AddressFamily IPv4).IPAddress) -Join ','

if (!$machineIp) {
  $machineIp=(Get-NetIPAddress -AddressFamily IPv4 `
    | Where-Object -FilterScript { `
      ( ! ($_.InterfaceAlias).StartsWith("vEthernet (") ) `
      -And $_.IPAddress -Ne "127.0.0.1" `
      -And $_.IPAddress -Ne "10.0.2.15" `
    }).IPAddress
}

$homeDir = $machineHome
if ($machineHome.startsWith('/')) {
  $homeDir = "C:$machineHome" # /Users/stefan from Mac -> C:/Users/stefan
}

function ensureDirs($dirs) {
  foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
      mkdir $dir
    }
  }
}

function installLCOW() {
  if (Test-Path "$env:ProgramFiles\Linux Containers") {
    Remove-Item -Recurse "$env:ProgramFiles\Linux Containers"
  }
  Write-Host "`n=== Enable LCOW"
  Write-Host "    Downloading LCOW LinuxKit ..."
  $ProgressPreference = 'SilentlyContinue'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Invoke-WebRequest -OutFile "$env:TEMP\linuxkit-lcow.zip" "https://github.com/linuxkit/lcow/releases/download/v4.14.23-v0.3.6/release.zip"
  Expand-Archive -Path "$env:TEMP\linuxkit-lcow.zip" -DestinationPath "$env:ProgramFiles\Linux Containers" -Force
  Remove-Item "$env:TEMP\linuxkit-lcow.zip"

  Write-Host "    Downloading docker nightly ..."
  Invoke-WebRequest -OutFile "$env:TEMP\docker-master.zip" "https://master.dockerproject.com/windows/x86_64/docker.zip"
  Expand-Archive -Path "$env:TEMP\docker-master.zip" -DestinationPath $env:ProgramFiles -Force
  Remove-Item "$env:TEMP\docker-master.zip"
}

# https://docs.docker.com/engine/security/https/
# Thanks to @artisticcheese! https://artisticcheese.wordpress.com/2017/06/10/using-pure-powershell-to-generate-tls-certificates-for-docker-daemon-running-on-windows/
function createCA($serverCertsPath) {
  Write-Host "`n=== Generating CA"
  $parms = @{
    type = "Custom" ;
    KeyExportPolicy = "Exportable";
    Subject = "CN=Docker TLS Root";
    CertStoreLocation = "Cert:\CurrentUser\My";
    HashAlgorithm = "sha256";
    KeyLength = 4096;
    KeyUsage = @("CertSign", "CRLSign");
    TextExtension = @("2.5.29.19 ={critical} {text}ca=1")
  }
  $rootCert = New-SelfSignedCertificate @parms

  Write-Host "`n=== Generating CA public key"
  $parms = @{
    Path = "$serverCertsPath\ca.pem";
    Value = "-----BEGIN CERTIFICATE-----`n" `
          + [System.Convert]::ToBase64String($rootCert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks) `
          + "`n-----END CERTIFICATE-----";
    Encoding = "ASCII";
    }
  Set-Content @parms
  return $rootCert
}

# https://docs.docker.com/engine/security/https/
function createCerts($rootCert, $serverCertsPath, $serverName, $ipAddresses, $clientCertsPath) {
  Write-Host "`n=== Generating Server certificate"
  $parms = @{
    CertStoreLocation = "Cert:\CurrentUser\My";
    Signer = $rootCert;
    KeyExportPolicy = "Exportable";
    Provider = "Microsoft Enhanced Cryptographic Provider v1.0";
    Type = "SSLServerAuthentication";
    HashAlgorithm = "sha256";
    TextExtension = @("2.5.29.37= {text}1.3.6.1.5.5.7.3.1", "2.5.29.17={text}DNS=$serverName&DNS=localhost&IPAddress=$($ipAddresses.Split(',') -Join '&IPAddress=')");
    KeyLength = 4096;
  }
  $serverCert = New-SelfSignedCertificate @parms

  $parms = @{
    Path = "$serverCertsPath\server-cert.pem";
    Value = "-----BEGIN CERTIFICATE-----`n" `
          + [System.Convert]::ToBase64String($serverCert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks) `
          + "`n-----END CERTIFICATE-----";
    Encoding = "Ascii"
  }
  Set-Content @parms

  Write-Host "`n=== Generating Server private key"
  $privateKeyFromCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($serverCert)
  $parms = @{
    Path = "$serverCertsPath\server-key.pem";
    Value = ("-----BEGIN RSA PRIVATE KEY-----`n" `
          + [System.Convert]::ToBase64String($privateKeyFromCert.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob), [System.Base64FormattingOptions]::InsertLineBreaks) `
          + "`n-----END RSA PRIVATE KEY-----");
    Encoding = "Ascii";
  }
  Set-Content @parms

  Write-Host "`n=== Generating Client certificate"
  $parms = @{
    CertStoreLocation = "Cert:\CurrentUser\My";
    Subject = "CN=clientCert";
    Signer = $rootCert ;
    KeyExportPolicy = "Exportable";
    Provider = "Microsoft Enhanced Cryptographic Provider v1.0";
    TextExtension = @("2.5.29.37= {text}1.3.6.1.5.5.7.3.2") ;
    HashAlgorithm = "sha256";
    KeyLength = 4096;
  }
  $clientCert = New-SelfSignedCertificate  @parms

  $parms = @{
    Path = "$clientCertsPath\cert.pem" ;
    Value = ("-----BEGIN CERTIFICATE-----`n" + [System.Convert]::ToBase64String($clientCert.RawData, [System.Base64FormattingOptions]::InsertLineBreaks) + "`n-----END CERTIFICATE-----");
    Encoding = "Ascii";
  }
  Set-Content @parms

  Write-Host "`n=== Generating Client key"
  $clientprivateKeyFromCert = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($clientCert)
  $parms = @{
    Path = "$clientCertsPath\key.pem";
    Value = ("-----BEGIN RSA PRIVATE KEY-----`n" `
          + [System.Convert]::ToBase64String($clientprivateKeyFromCert.Key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob), [System.Base64FormattingOptions]::InsertLineBreaks) `
          + "`n-----END RSA PRIVATE KEY-----");
    Encoding = "Ascii";
  }
  Set-Content @parms

  copy $serverCertsPath\ca.pem $clientCertsPath\ca.pem
}

function updateConfig($daemonJson, $serverCertsPath, $enableLCOW, $experimental) {
  $config = @{}
  if (Test-Path $daemonJson) {
    $config = (Get-Content $daemonJson) -join "`n" | ConvertFrom-Json
  }

  if (!$experimental) {
    $experimental = $false
  }
  if ($enableLCOW) {
    $experimental = $true
  }
  $config = $config | Add-Member(@{ `
    hosts = @("tcp://0.0.0.0:2376", "npipe://"); `
    tlsverify = $true; `
    tlscacert = "$serverCertsPath\ca.pem"; `
    tlscert = "$serverCertsPath\server-cert.pem"; `
    tlskey = "$serverCertsPath\server-key.pem"; `
    experimental = $experimental `
    }) -Force -PassThru

  Write-Host "`n=== Creating / Updating $daemonJson"
  $config | ConvertTo-Json | Set-Content $daemonJson -Encoding Ascii
}

function createMachineConfig ($machineName, $machineHome, $machinePath, $machineIp, $serverCertsPath, $clientCertsPath) {
  $machineConfigJson = "$machinePath\config.json"

  $config = @"
{
    "ConfigVersion": 3,
    "Driver": {
        "IPAddress": "$machineIp",
        "MachineName": "$machineName",
        "SSHUser": "none",
        "SSHPort": 3389,
        "SSHKeyPath": "",
        "StorePath": "$machineHome/.docker/machine",
        "SwarmMaster": false,
        "SwarmHost": "",
        "SwarmDiscovery": "",
        "EnginePort": 2376,
        "SSHKey": ""
    },
    "DriverName": "generic",
    "HostOptions": {
        "Driver": "",
        "Memory": 0,
        "Disk": 0,
        "EngineOptions": {
            "ArbitraryFlags": [],
            "Dns": null,
            "GraphDir": "",
            "Env": [],
            "Ipv6": false,
            "InsecureRegistry": [],
            "Labels": [],
            "LogLevel": "",
            "StorageDriver": "",
            "SelinuxEnabled": false,
            "TlsVerify": true,
            "RegistryMirror": [],
            "InstallURL": "https://get.docker.com"
        },
        "SwarmOptions": {
            "IsSwarm": false,
            "Address": "",
            "Discovery": "",
            "Agent": false,
            "Master": false,
            "Host": "tcp://0.0.0.0:3376",
            "Image": "swarm:latest",
            "Strategy": "spread",
            "Heartbeat": 0,
            "Overcommit": 0,
            "ArbitraryFlags": [],
            "ArbitraryJoinFlags": [],
            "Env": null,
            "IsExperimental": false
        },
        "AuthOptions": {
            "CertDir": "$machineHome/.docker/machine/machines/$machineName",
            "CaCertPath": "$machineHome/.docker/machine/machines/$machineName/ca.pem",
            "CaPrivateKeyPath": "$machineHome/.docker/machine/machines/$machineName/ca-key.pem",
            "CaCertRemotePath": "",
            "ServerCertPath": "$machineHome/.docker/machine/machines/$machineName/server.pem",
            "ServerKeyPath": "$machineHome/.docker/machine/machines/$machineName/server-key.pem",
            "ClientKeyPath": "$machineHome/.docker/machine/machines/$machineName/key.pem",
            "ServerCertRemotePath": "",
            "ServerKeyRemotePath": "",
            "ClientCertPath": "$machineHome/.docker/machine/machines/$machineName/cert.pem",
            "ServerCertSANs": [],
            "StorePath": "$machineHome/.docker/machine/machines/$machineName"
        }
    },
    "Name": "$machineName"
}
"@

  Write-Host "`n=== Creating / Updating $machineConfigJson"
  $config | Set-Content $machineConfigJson -Encoding Ascii

  Write-Host "`n=== Copying Client certificates to $machinePath"
  copy $serverCertsPath\ca.pem $machinePath\ca.pem
  copy $clientCertsPath\cert.pem $machinePath\cert.pem
  copy $clientCertsPath\key.pem $machinePath\key.pem
}

function sed($file, $search, $replace) {
  Write-Host "Replacing '$search' with '$replace' in file '$file'"
  if (!(Test-Path "$file.bak")) {
    Copy-Item "$file" "$file.bak"
    $content = [io.file]::ReadAllBytes($file)
    $m = [Regex]::Match([Text.Encoding]::ASCII.GetString($content), [Regex]::Escape($search))
    if ($m.Success) {
      Write-Host "Found '$search' at position $($m.Index)"
      $enc = [system.Text.Encoding]::UTF8
      [Byte[]]$replacementString = $enc.GetBytes($replace);
      $fileStream = [System.IO.File]::Open($file, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
      $binaryWriter = New-Object System.IO.BinaryWriter($fileStream)
      $binaryWriter.BaseStream.Position = $m.Index;
      $binaryWriter.Write($replacementString)
      $fileStream.Close()
    } else {
      Write-Host "'$search' not found."
    }
  } else {
    Write-Host "Fix already applied."
  }
}

$dockerData = "$env:ProgramData\docker"
$userPath = "$env:USERPROFILE\.docker"

ensureDirs @("$dockerData\certs.d", "$dockerData\config", "$userPath")

$serverCertsPath = "$dockerData\certs.d"
$clientCertsPath = "$userPath"
$rootCert = createCA "$dockerData\certs.d"

createCerts $rootCert $serverCertsPath $serverName $ipAddresses $clientCertsPath
updateConfig "$dockerData\config\daemon.json" $serverCertsPath $enableLCOW $experimental

if ($machineName) {
  $machinePath = "$env:USERPROFILE\.docker\machine\machines\$machineName"
  ensureDirs @($machinePath)
  createMachineConfig $machineName $machineHome $machinePath $machineIp $serverCertsPath $clientCertsPath
}

Write-Host "`n=== Copying Docker Machine configuration to $homeDir\.docker\machine\machines\$machineName"
if (Test-Path "$homeDir\.docker\machine\machines\$machineName") {
  rm -recurse "$homeDir\.docker\machine\machines\$machineName"
}
Copy-Item -Recurse "$env:USERPROFILE\.docker\machine\machines\$machineName" "$homeDir\.docker\machine\machines\$machineName"

Write-Host "Restarting Docker"
Stop-Service docker
dockerd --unregister-service
if ($enableLCOW) {
  installLCOW  
}
dockerd --register-service  
Write-Host "Reducing minimum API version from 1.24 to 1.15"
sed "$env:ProgramFiles\docker\dockerd.exe" "1.24" "1.15"

Start-Service docker

Write-Host "Opening Docker TLS port"
& netsh advfirewall firewall add rule name="Docker TLS" dir=in action=allow protocol=TCP localport=2376
