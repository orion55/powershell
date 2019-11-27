function ClearUI{
	$bckgrnd = "DarkBlue"
	$Host.UI.RawUI.BackgroundColor = $bckgrnd
	$Host.UI.RawUI.ForegroundColor = 'White'
	$Host.PrivateData.ErrorForegroundColor = 'Red'
	$Host.PrivateData.ErrorBackgroundColor = $bckgrnd
	$Host.PrivateData.WarningForegroundColor = 'Magenta'
	$Host.PrivateData.WarningBackgroundColor = $bckgrnd
	$Host.PrivateData.DebugForegroundColor = 'Yellow'
	$Host.PrivateData.DebugBackgroundColor = $bckgrnd
	$Host.PrivateData.VerboseForegroundColor = 'Green'
	$Host.PrivateData.VerboseBackgroundColor = $bckgrnd
	Clear-Host
}

function testDir($dirs1){
	foreach ($d1 in $dirs1){
		#�������� ������������� �����
		if (!(Test-Path -Path $d1)){
			Write-Log -EntryType Error -Message "���� $d1 �� ������!"
			Write-Log -EntryType Information -Message "������� ����� ������� ��� �����������"
			Read-Host "������� Enter"
			Exit
		}
	}
}

function testFiles($files){
	foreach ($f1 in $files){
		#�������� ������������� ������
		if (!(Test-Path $f1)){
			Write-Log -EntryType Error -Message "���� $f1 �� ������!"
			Write-Log -EntryType Information -Message "������� ����� ������� ��� �����������"
			Read-Host "������� Enter"
			Exit
		}
	}
}

#��������� ���������� �� ��������, ���� �� ����������, �� ������?
function createDir($dirList){
	foreach ($curPath in $dirList){
		#�������� ������������� �����
		if (!(Test-Path -Path $curPath)){
			New-Item -ItemType directory -Path $curPath | out-Null
		}
	}
}