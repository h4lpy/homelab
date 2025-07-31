# Domain Controller Setup

```
sconfig
```

### Hostname:

```
> sconfig

> 2

> DC01
```

### Network Settings

```
> sconfig

# Set static IP
> 8

  Enter selection (Blank=Cancel): 1
  Select (D)HCP or (S)tatic IP address (Blank=Cancel): S
  Enter static IP address (Blank=Cancel): 192.168.37.155
  Enter subnet mask (Blank=255.255.255.0):
  Enter default gateway (Blank=Cancel): 192.168.37.2

# DNS
> 8

  Enter selection (Blank=Cancel): 2
  Enter new preferred DNS server (Blank=Cancel): 192.168.37.155
  Enter alternate DNS server (Blank=None):
  Successfully assigned DNS server(s).


```


### Active Directory Install/Configruation

```
> Get-WindowsFeature | ? {$_.Name -LIKE "AD*"}

> Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```