# Workstation Configuration

## Sysmon Installation

Download [Sysmon](https://learn.microsoft.com/sysinternals/downloads/sysmon).

```powershell
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile ".\Sysmon.zip"
Expand-Archive ".\Sysmon.zip"
```

Using [SwiftOnSecurity's configuration](https://github.com/SwiftOnSecurity/sysmon-config/blob/master/sysmonconfig-export.xml):

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/refs/heads/master/sysmonconfig-export.xml" -OutFile ".\sysmonconfig-export.xml"
```

Install (as Administrator):

```
.\Sysmon64.exe -accepteula -i ".\sysmonconfig-export.xml"
```
