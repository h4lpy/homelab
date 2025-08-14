# Domain Controller Setup

## Initial Configuration

1. Use `sconfig` to:

Change the hostname:

```shell
> 2
> DC01
```

2. Change the IP address to static:

```shell
> 8
  Enter selection (Blank=Cancel): 1
  Select (D)HCP or (S)tatic IP address (Blank=Cancel): S
  Enter static IP address (Blank=Cancel): 192.168.37.155
  Enter subnet mask (Blank=255.255.255.0):
  Enter default gateway (Blank=Cancel): 192.168.37.2
```

3. Change DNS to point to DC:

```shell
> 8
  Enter selection (Blank=Cancel): 2
  Enter new preferred DNS server (Blank=Cancel): 192.168.37.155
  Enter alternate DNS server (Blank=None):
  Successfully assigned DNS server(s).
```

## Active Directory Install/Configruation

```shell
> Get-WindowsFeature | ? {$_.Name -LIKE "AD*"}

> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

> Import-Module ADDSDeployment

> Install-ADDSForest
...
DomainName: e-corp.com
SafeModeAdministratorPassword: **********
Confirm SafeModeAdministratorPassword: **********
```

DNS settings change to `127.0.0.1` during installation; need to revert back to pointing to Domain Controller:

```shell
> Get-NetIPAddress -IPAddress 192.168.37.155
IPAddress         : 192.168.37.155
InterfaceIndex    : 4

> Set-DnsClientServerAddress -InterfaceIndex 4 -ServerAddresses 192.168.37.155

# Verify change
> Get-DNSClientServerAddress
```

