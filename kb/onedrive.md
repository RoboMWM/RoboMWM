### Block "Backup your PC" prompt

[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMBlockOptIn"=dword:00000001

set value to 2 to also force folders back to local PC

From https://learn.microsoft.com/en-us/sharepoint/use-group-policy#prevent-users-from-moving-their-windows-known-folders-to-onedrive

### Block OneDrive app entirely

[HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive]"DisableFileSyncNGSC"=dword:00000001

From https://github.com/ntdevlabs/tiny11builder/issues/467#issuecomment-3365220586