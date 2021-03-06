$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
$orig_path = "$dir1\cb_out"
$mosk_path = "$dir1\test_msk"


function revName($filename){
	$num = $filename.Name.split('.')[0].Substring(8,3)
	$file = Get-ChildItem "a*.$num" -path $orig_path	
	return $file.Name
}

$refContents = Get-ChildItem "$orig_path\*.xml"
$difContents = Get-ChildItem "$mosk_path\*.xml"    

Clear-Host
$difFiles = Compare-Object -ReferenceObject $refContents -DifferenceObject $difContents -Property ('Name', 'Length') -PassThru |  where-object { $_.SideIndicator -eq '<='} | select Name
$count = ($difFiles|Measure-Object).count

foreach($file in $difFiles){
    revName($file)
}