try {. $PSScriptRoot\..\..\LoadPSD1.ps1} catch {}

Remove-Item temp.xlsx -ErrorAction Ignore

$data = Invoke-Sum -data (Get-Process) -dimension Company -measure Handles, PM, VirtualMemorySize

$c = New-ExcelChartDefinition -Title "ProcessStats" `
    -ChartType LineMarkersStacked `
    -XRange "Processes[Name]" `
    -YRange "Processes[PM]","Processes[VirtualMemorySize]" `
    -SeriesHeader "PM","VM"

$data |
    Export-Excel -Path temp.xlsx -AutoSize -TableName Processes -ExcelChartDefinition $c  -Show
