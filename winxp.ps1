Import-Module ActiveDirectory
$then = (Get-Date).AddDays(-10)
Get-ADComputer -Filter {(lastLogonDate -lt $then) -and (OperatingSystem -like "*XP*") -and (Enabled -eq $true)} | Format-Table -HideTableHeaders -Property Name | Out-File -FilePath d:\ps1\Outfile.txt