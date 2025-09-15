<#
.SYNOPSIS
  Create and populate an Active Directory environment from schema file.

.DESCRIPTION
  - Creates OUs defined in schema.organizational_units
  - Creates groups defined in schema.groups
  - Creates users defined in schema.users (SAM = firstInitial + lastname)
  - (OPTIONAL) Weakens domain password policy
  - (OPTIONAL) Exports plaintext credentials

.EXAMPLE
  .\Create-E-Corp.ps1 -JSONFile .\e-corp_schema.json -WeakenPasswordPolicy -ExportPlaintextPasswords

.PARAMETER JSONFile
  Path to JSON schema file (REQUIRED)

.PARAMETER WeakenPasswordPolicy
  If supplied, weakens domain password policy

.PARAMETER ExportPlaintextPasswords
  If supplied, writes plaintext username:password pairings to .\e-corp_users.txt

#>

param(
    [Parameter(Mandatory=$true)][string] $JSONFile,
    [switch] $WeakenPasswordPolicy,
    [switch] $ExportPlaintextPasswords
);

# Read in schema
$schema = Get-Content -Path $JSONFile -Raw | ConvertFrom-JSON
$Domain = $schema.domain

function DomainToDN([string] $domain) {
    ($domain.Split('.') | ForEach-Object { "DC=$_" } ) -join ","
}
$DomainDN = DomainToDN $Domain
Write-Output "[+] Domain: $Domain  (DN: $DomainDN)"

# Weaken password policy
if ($WeakenPasswordPolicy) {
    Write-Warning "[!] Weakening domain password policy (ComplexityDisabled, MinLen=1)"
    Set-ADDefaultDomainPasswordPolicy `
        -Identity $DomainDN `
        -ComplexityEnabled $false `
        -MinPasswordLength 1 `
        -ErrorAction Stop
}

# Read password list
$passwordFile = ".\data\passwords.txt"
if (-not (Test-Path $passwordFile)) {
    Write-Error "[#] Error: Password list not found at $passwordFile"
    exit 1
}
$passwordList = Get-Content -Path $passwordFile

# Create OUs
foreach ($ou in $schema.organizational_units) {
    $ouDN = "OU=$ou,$DomainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        Write-Output "[+] Creating OU: $ou"
        New-ADOrganizationalUnit -Name $ou -Path $DomainDN -ErrorAction Stop
    } else {
        Write-Verbose "[#] OU $ou already exists"
    }
}

$groupsOU = "OU=Groups,$DomainDN"
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$groupsOU'" -ErrorAction SilentlyContinue)) {
    Write-Output "[+] Creating Groups OU"
    New-ADOrganizationalUnit -Name "Groups" -Path $DomainDN -ErrorAction Stop
}

# Create groups (inside OU=Groups)
foreach ($group in $schema.groups) {
    $groupName = $group.name
    $groupObj = Get-ADGroup -LDAPFilter "(cn=$groupName)" -SearchBase $groupsOU -ErrorAction SilentlyContinue
    if (-not $groupObj) {
        Write-Output "[+] Creating group: $groupName in Groups OU"
        New-ADGroup -Name $groupName -GroupScope Global -Path $groupsOU -ErrorAction Stop
        $groupObj = Get-ADGroup -LDAPFilter "(cn=$groupName)" -SearchBase $groupsOU -ErrorAction Stop
    } else {
        Write-Verbose "[#] Group $groupName already exists"
    }
}

$Global:UserMap = @{}

# (HELPER) Create stable SAM accounts
function Make-SamAccountName {
    param([string] $fullname)

    $parts = $fullname.Trim() -split '\s+'
    $firstname = $parts[0]
    $lastname = if ($parts.Count -gt 1) { $parts[-1] } else { $parts[0] }
    $base = (($firstname.Substring(0, 1)) + $lastname).ToLower()

    $sam = $base
    $i = 0

    # Ensures name is unique
    while (Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue) {
        $i++
        $sam = "$base$i"
    }
    return @{Sam = $sam; Firstname = $firstname; Lastname = $lastname}
}

# Create users
$created = @{}
foreach ($user in $schema.users) {
    $entry = Make-SamAccountName -fullname $user.name
    $sam = $entry.Sam
    $firstname = $entry.Firstname
    $lastname = $entry.Lastname
    $upn = "$sam@$Domain"

    $plainPassword = Get-Random -InputObject $passwordList
    $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

    $ouPath = if ($schema.organizational_units -contains $user.ou) { "OU=$($user.ou),$DomainDN" } else { $DomainDN }

    Write-Output "[+] Creating user: $($user.name) -> $sam (OU: $ouPath)"
    Write-Output "[+] Creating user $user.name (username: $sam) with password '$plainPassword'";
    New-ADUser `
        -Name $user.name `
        -GivenName $firstname `
        -Surname $lastname `
        -SamAccountName $sam `
        -UserPrincipalName $upn `
        -AccountPassword $securePassword `
        -Enabled $true `
        -PasswordNeverExpires $true `
        -ChangePasswordAtLogon $false `
        -Title $user.title -ErrorAction Stop
    
    $created[$sam] = $plainPassword

    $Global:UserMap[$user.name.Trim()] = $sam
    $Global:UserMap[$sam] = $sam
}

# Write username:password mappings to file
if ($ExportPlaintextPasswords) {
    $outPath = ".\e-corp_users.txt"
    Write-Warning "[!] Exporting plaintext credentials to $outPath"
    $created.GetEnumerator() | ForEach-Object { "$($_.Key),$($_.Value)" } | Set-Content -Path $outPath -Force
}

# Add users to groups
foreach ($group in $schema.groups) {
    $groupName = $group.name.Trim()

    $groupObj = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue

    if (-not $groupObj) {
        $groupObj = Get-ADGroup -LDAPFilter "(cn=$groupName)" -SearchBase $groupsOU -ErrorAction SilentlyContinue
    }

    if (-not $groupObj) {
        Write-Warning "[#] Group $groupName could not be resolved; skipping member assignment"
        continue
    }

    $members = $group.members
    if ($null -eq $members -or $members.Count -eq 0) { continue }

    $resolvedMembers = @()
    foreach ($member in $members) {
        $m = $member.Trim()
        if ($Global:UserMap.ContainsKey($m)) {
            $resolvedMembers += $Global:UserMap[$m]
        } else {
            Write-Warning "[#] Error: $groupName member $m could not be resolved; skipping"
        }
    }

    if ($resolvedMembers.Count -gt 0) {
        Write-Output "[+] Adding to group $groupName : $($resolvedMembers -join ',')"
        Add-ADGroupMember -Identity $groupObj -Members $resolvedMembers -ErrorAction Stop
    }
}

Write-Output "[+] Created $($created.Count) users"
Write-Output "[+] $Domain successfully populated"
