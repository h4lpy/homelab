# Homelab - `E-CORP.LOCAL`

This repository holds files/scripts/etc. related to my homelab setup (`E-CORP.LOCAL`).

Contents:






```
Start-Service WinRM

Set-Item wsman:\localhost\Client\TrustedHosts -value [DC IP]

New-PSSession -ComputerName [DC IP] -Credential (Get-Credential)

Enter-PSSession [Session ID]
```