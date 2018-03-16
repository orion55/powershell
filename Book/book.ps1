$dir1 = Split-Path -Path $myInvocation.MyCommand.Path -Parent
[string]$book = "d:\book"
[string]$fileList = "$dir1\book_list.txt"

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

function Test_dir($dirs1){	
	foreach ($d1 in $dirs1){
		#проверка существования путей
		if (!(Test-Path -Path $d1)){
			Write-Host "Путь $d1 не найден!" -ForegroundColor Red
			Write-Host "Нажмите любую клавишу для продолжения" 
			Read-Host "Нажмите Enter"			
			Exit
		}
	}
}

ClearUI
Set-Location $book

Test_dir(@($book))
$fb2 = Get-ChildItem -Path $book "*.fb2" -Recurse
$count_fb2 = ($fb2 | Measure-Object).count
Write-Host "Найдено $count_fb2 файл(а) в $book!" -ForegroundColor Green
if ($count_fb2 -eq 0){
    exit
}

foreach ($f in $fb2){
	Write-Host -ForegroundColor Cyan $f.Name
    
    [xml]$content = Get-Content $f.FullName -Encoding UTF8
    $bookTitle = $content.FictionBook.description.'title-info'.'book-title'
    $firstName = $content.FictionBook.description.'title-info'.author.'first-name'
    $middleName = $content.FictionBook.description.'title-info'.author.'middle-name'
    $lastName = $content.FictionBook.description.'title-info'.author.'last-name'
    $str = ''
    $bookTitle = $bookTitle.trim()
    if ($bookTitle -ne '') {
        $str += $bookTitle
    }
    $str += ' - '
    
    if ($lastName -ne '') {        
        $str += $lastName
    }
    
    if ($middleName -ne '') {        
        $str += ' ' + $middleName
    }
    
    if ($firstName -ne '') {        
        $str += ' ' + $firstName
    }
    $str | Out-File $fileList -Encoding utf8 -Append
}