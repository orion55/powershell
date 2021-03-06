Import-module ActiveDirectory 

$Groups=Get-ADGroup -filter * 

foreach ($group in $Groups) { 

$Members=Get-ADGroupMember -Identity $group.name 

foreach ($Member in $Members) {     
    $Report = $Group.Name + "," + $Member.SamAccountName 
    Add-Content C:\temp\members.csv $Report
    }
}