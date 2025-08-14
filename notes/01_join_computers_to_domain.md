# Join Computers To Domain

## Change DNS settings to point to Domain Controller

```shell
> Get-NetIPAddress -IPAddress 192.168.37.155
IPAddress         : 192.168.37.142
InterfaceIndex    : 5

> Set-DnsClientServerAddress -InterfaceIndex 5 -ServerAddresses 192.168.37.155

# Verify change
> Get-DNSClientServerAddress
```

## Join the Computer to the Domain

#### GUI

Settings -> Access work or school -> Add a work or school account -> Connect

Join this device to a local Active Directory domain

```
e-corp.com
```

#### PowerShell

```shell
> Add-Computer -DomainName e-corp.com -Credential e-corp\Administrator -Restart -Force

> Rename-Computer -NewName "ws01" -DomainCredential e-corp\Administrator -Restart -Force
```

## Remoting into the Domain Controller

```shell
Start-Service WinRM

Set-Item wsman:\localhost\Client\TrustedHosts -value 192.168.37.155

New-PSSession -ComputerName 192.168.37.155 -Credential (Get-Credential)

Enter-PSSession [Session ID]
```

## Copy Files/Folder to the Domain Controller

```shell
$dc_conn = New-PSSession 192.168.37.155 -Credential (Get-Credential)

Copy-Item C:\Local\Path\Of\File -ToSession $dc_conn C:\Destination\Path

Copy-Item C:\Local\Path\Of\Folder -ToSession $dc_conn C:\Destination\Path -Recurse

Enter-PSSession $dc_conn
```