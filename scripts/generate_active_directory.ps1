# Read in AD schema from command-line parameters
param( [Parameter(Mandatory=$true)] $JSONFile );
$schema = Get-Content -Path $JSONFile | ConvertFrom-JSON;

$Global:Domain = $schema.domain;

$passwordList = [System.Collections.ArrayList](Get-Content -Path ".\data\passwords.txt");

function WeakenPasswordPolicy() {
    Set-ADDefaultDomainPasswordPolicy `
        -Identity "DC=e-corp,DC=com" `
        -ComplexityEnabled $false `
        -MinPasswordLength 1
}

function CreateADGroup() {
    param( [Parameter(Mandatory=$true)] $group );

    $name = $group.name;
    Write-Output "[i] Creating group $name";

    New-ADGroup -name $group.name -GroupScope Global;
}

function CreateADUser() {
    param( [Parameter(Mandatory=$true)] $user );

    $name = $user.name;
    $firstname, $lastname = $user.name.split(' ');
    $username = ($firstname[0] + $lastname).ToLower();
    $SAMAccountName = $username;
    $UserPrincipalName = "$username@$Global:Domain";
    $chosenPassword = Get-Random -InputObject $passwordList;
    $password = (ConvertTo-SecureString $chosenPassword -AsPlainText -Force);

    Write-Output "[i] Creating user $name (username: $username) with password '$chosenPassword'";

    New-ADUser `
        -Name $name `
        -GivenName $firstname `
        -Surname $lastname `
        -SamAccountName $SAMAccountName `
        -UserPrincipalName $UserPrincipalName `
        -AccountPassword $password `
        -Enabled $true `
        -PasswordNeverExpires $true;

    $output = "$username,$chosenPassword";
    Add-Content -Path ".\e-corp_users.txt" -Value $output;
}

function AddUserToGroup() {
    param( [Parameter(Mandatory=$true)] $group );

    $members = $group.members;
    $name = $group.name;

    try {
        Write-Output "[i] Adding members to group $($name): $($members -join ',')";
        Get-ADGroup -Identity $name;
        Add-ADGroupMember -Identity $name -Members $members;
    } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Warning "[!] Unable to add $members to group $groupname";
    }    
}

Write-Output "[+] Weakening password policy for $Global:Domain";

# 1 - Weaken password policy for domain
WeakenPasswordPolicy

Write-Output "[+] Generating users and groups for $Global:Domain";

# 2 - Create groups
foreach ($group in $schema.groups) {
    CreateADGroup $group;
}

# 3 - Create users
foreach ($user in $schema.users) {
    CreateADUser $user;
}

# 4 - Add users to groups
foreach ($group in $schema.groups) {
    AddUserToGroup $group;
}

Write-Output "[+] $Global:Domain successfully populated";
