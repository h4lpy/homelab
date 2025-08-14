$usersToRemove = Get-Content -Path ".\e-corp_users.txt" | ForEach-Object { ($_ -split ',')[0] }

foreach ($username in $usersToRemove) {
    if (Get-ADUser -Identity $username -ErrorAction SilentlyContinue) {
        Write-Output "[i] Removing user $username";
        Remove-ADUser -Identity $username -Confirm:$false;
    }
}

$groupsToRemove = @("Security Team", "Infrastructure", "Executive Team", "Employees");

foreach ($group in $groupsToRemove) {
    if (Get-ADGroup -Identity $group -ErrorAction SilentlyContinue) {
        Write-Output "[i] Removing group $group";
        Remove-ADGroup -Identity $group -Confirm:$false;
    }
}

Write-Output "[i] Cleaning up outputted files"

if (Test-Path ".\e-corp_users.txt") {
    Remove-Item ".\e-corp_users.txt";
}

Write-Output "[+] Reverted E-CORP.COM to clean state"