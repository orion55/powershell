$currentPath = Split-Path -Path $myInvocation.MyCommand.Path -Parent

cls

$handle = &"$currentPath\handle.exe"
#$handle | Out-File 'd:\1111.txt' -Encoding UTF-8
foreach ($line in $handle) { 
        if ($line -match '\S+\spid:') {
            $exe = $line			
        } 
        elseif ($line -match 'D:\\Ps1\\UtaMail\\IN_MAIL')  { 
            "$exe - $line"
        }
     }