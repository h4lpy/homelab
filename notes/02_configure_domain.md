# Configure Domain

## Generate/Populate Users and Groups

On DC from `scripts` directory:

```
.\generate_active_directory.ps1 -JSONFile e-corp_schema.json
```

This will create the groups and populate them accordingly with the users (see [schema](/scripts/e-corp_schema.json)), and create a final `e-corp_users.txt` file with the passwords for each account.

## Teardown/Revert `e-corp.com`

On DC from `scripts` directory:

```
.\teardown_active_directory.ps1
```

This will remove all users and groups as configured by `generate_active_directory.ps1` and cleanup any outputted files from its execution.
