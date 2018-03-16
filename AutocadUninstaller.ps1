<#
.Synopsis
    Удаляет программы компании autodesk.
.Description
    Удаляет все программы компании autodesk, утсановленные на компьютере. Скрипт так же позволяет удалять и другие программы, 
    при устовии что они были установлены при помощи msi. 
.Parameter ProgramName
    Название программы для удаления, на случай когда нужно удалить не autodesk.
.Parameter Iterations
    Количество попыток удаления.
.Parameter Silent
    Не показывать штатный интерфейс процесса удаления msi.
.Parameter Verysilent
    Полностью тихий режим. Скрыт штатный интерфейс процесса удаления msi и консоли, с процессом работы скрипта. 
.Parameter Restart
    Перезагрузить компьютер после завершения работы скрипта.
.Example
    ./AutocadUninstaller
.Example
    ./AutocadUninstaller -Iterations 3 -Silent -Restart
.Example
    ./AutocadUninstaller -ProgramName 7-Zip -Iterations 1 -Verysilent
#>

# Параметры запуска скрипта.
param
(
    # Имя программы для удаления;
    [alias("program,p")][string]$ProgramName = "autodesk",

    # Кол-во попыток удалить программу
    [alias("i")][int]$Iterations = 2, 

    # Перезагрузка ПК по завершению работы скрипта
    [alias("r")][switch]$Restart,

    # Путь для файлау лога
    [alias("lp")][string]$LogPath = $PSScriptRoot + "\AutodeskUninstaller.log",

    # Вызов справки, при этом основная работа скрипта не выполняется 
    [alias("h")][switch]$Help,

    # Показать интерфейс удаления msi 
    [alias("s")][switch]$Silent,

    # Тоже, что с параметром Silent + Скрыть консоль с информацией о ходе работы скрипта
    [alias("ss")][switch]$Verysilent
)

$script_version = "v1.6"

# Функция выводит время старта работы скрипта в консоль и в лог, а за тем запускает все основные функции
Function Run()
{
    Write-log "Script $script_version runing`r`n" -TimeStamp -Path $LogPath
	For ($i=1; $i -le $Iterations; $i++) 
    {
		# Текущая итерация и время ее запуска
		Write-log("Start iteration $i") -Path $LogPath     		

		# Получаем системное время
		$time = Get-Date -Format g
	
		# Убиваем все запущенные процессы связаные с нужным продуктом. Подробнее с.м. функцию KillProcesses ниже
		KillProcesses($ProgramName)
	
		# Останавливаем все службы, связаные с нужным продуктом. Подробнее с.м. функцию StopServices ниже	
		StopServices($ProgramName)
	
		# Запускаем удаление. Подробнее с.м. функцию Uninstall ниже
		PrepareToUninstall($ProgramName)
	}
}


# Задает размер окна консоли, цвет текста, цвет фона
Function ConsoleSetups([bool] $ShowConsole = $True)
{	
    # .Net методы для отображения/скрытия консоли
	Add-Type -Name Window -Namespace Console -MemberDefinition '
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();

	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
	'
	# Пытаемся получить консоль
	$consolePtr = [Console.Window]::GetConsoleWindow()
	
    # Вызываем метод ShowWindow и передаем в него $consolePtr - экземпляр консоли. 
    # Вторым параметром передаем 0/$Fales - если хотим скрыть консоль или 1/$True - если хотим показать.
    # Метод вернет False, если переданная консоль == NULL, что скорее всего значит что скрипт запущен не в консоли. Значит дальнейщее выполнение функции Confic бессмысленно, так что return.
	if(![Console.Window]::ShowWindow($consolePtr, $ShowConsole))
    {
        return;
    }
	
	# Цвет текста
    [console]::ForegroundColor = "green" #"yellow" "white"	
	
	# Цвет фона	
	[console]::BackgroundColor = "black"
	
	# Получаем объект UI. Он нужен для возможности в дальнейшем установить размер окна консоли 
	$ui = $Host.UI.RawUI
	
	# Получаем текущий размер буфера окна. Чем больше буфер - тем больше размер сохраняемой информации в окне консоли. если лимит буфера будит исчерпан - старая информация начнет перезаписываться новой
	$bufferSize = $ui.BufferSize
	
    # Получаем текущий размер окна консоли
	$windowSize = $ui.WindowSize
	
    # Устанавливаем желаемый размер окна, пользуаясь служебной функцией Size, которая возвращает необходимый нам объект Host.Size. Если размер окна будит превышать максимальный размер монитора - мы получим ошибку "WindowSize": "Window cannot be wider than X". Установленный размет 160 максимальный для запуска на 17" мониторах.
	$windowSize = Size 160 50	
	
    # Устанавливаем размер буфера по ширине, равный ширине окна, а в высоту оставляем значение по умолчанию (ибо его хватает)
	$ui.BufferSize = Size $windowSize.width $bufferSize.height
	
	# Передаем новый размер окна в объект UI
	$ui.WindowSize = $windowSize
}


# Служебная функция для получения объекта Host.Size
Function Size($w, $h)
{
    New-Object System.Management.Automation.Host.Size($w, $h)
}


# Фунция завершает все запущенные процессы, название издателья которых содержит строку $Name.
Function KillProcesses([String]$Name)
{
	# Получаем все процессы командлетом Get-Process. Затем делаем выборку командлетом Where-Object : в фигурных скобках создается системная переменная "$_", для временного хранения текущего объекта-процесса при переборе среди остальных. Мы знаем что каждый объект-процесс содержит параметр с названием производителя, доступ к которому можно получить так : $_.company. Дальше идет оператор -like, который позволяет использовать регулярные выражения. В нашем случае регулярка *$Name*. Она ишет все процессы содержащие строку в переменной $Name в названии производителя. Строка $Name передается в функцию в качестве параметра из функции Run() с.м выше. Результат выборки сохраняется в переменной-массиве $AutodeskProcesses.
	$AutodeskProcesses = Get-Process | Where-Object {$_.company -like "*$Name*"}
	
	# В цикле foreach проходимся по каждому объекту-процессу из массива $AutodeskProcesses.
	foreach ($Process in $AutodeskProcesses)
	{
		# Вызываем командлет Stop-Process с ключем -processname, которому передаем имя процесса, который хранится в объекте-процессе, как $process.Name. Ключь -Force заставит процесс завершиться принудительно, даже если тот занят в данный момент чемто важным.
		Stop-Process -processname $Process.Name -Force
		
		# Пишем отчет в консоль и в фаил с.м. функцию Write-log.
		Write-log("Process killed  -  " + $Process.Name) -Path $LogPath
	}
}


# Функция останавливает все запущенные службы, в отображаемом названии которых содержится строка $Name
Function StopServices([String]$Name)
{
    # Получаем все службы оператором Get-Service. Затем делаем выборку среди них оператором Where-Object : в фигурных скобках создается переменная "$_", для временного хранения терущей объекта-службы при переборе среди остальных. Каждый объект-служба содержит параметр DisplayName - отображаемое имя службы. (есть параметр Name, а есть DisplayName. Первый это настоящее название службы, например "gupdate", а отображаемое имя - для большей понятности. Например для "gupdate" отображаемое имя это "Служба Google Update". Для более точного  будим искать по отображаемому имени службы. Оператор -like позволяет использовать регулярные выражения. В нашем случае регулярка *$Name* ишет все службы содержащие в своем отображаемом названии строку $Name.
	$AutodeskServices = Get-Service | Where-Object {$_.DisplayName -like "*$Name*" -and $_.StartType -ne "Disabled"}
	
	# В цикле foreach проходимся по каждому объекту-службе из массива $AutodeskServices.
	foreach($Service in $AutodeskServices)
    {
		# Останавливаем службу. Ключь -Force остановит службу принудительно, даже если она занята в данный момент чемто важным.
		Stop-Service $Service.Name -Force
		
		# Устанавливаем режим запуска для службы как Disabled(Остановлена). Это нужно для того что бы служба не запустилась сама.
        Set-Service $Service.Name -StartupType Disabled
		
		# Вывод информации в консоль и в фаил лога с.м. функцию Write-log.
        Write-log("Service stopped  -  " + $Service.Name) -Path $LogPath
    }
}


# Функция удаляет программы, содржащие в своем названии указанную строку $Name 
Function PrepareToUninstall([String]$Name)
{
    Write-log("Searching msi to uninstall...") -Path $LogPath
	# Используя камандлет Get-WmiObject, обращаемся к классу win32_product для получения установленных в системе программ (только тех, что были установленны при помощи msi). Затем делаем выборку среди них оператором Where-Object : в фигурных скобках создается переменная "$_", для временного хранения терущго объекта-программы при переборе среди остальных. Для каждой программы мы делаем проверку : $_.vendor -like "*$Name*" -or $_.name -like "*$Name*" т.е. содерит ли строка с производителем, в любой своей части, строку из переменной $Name. Дальше идет -or что значит ИЛИ и проверка на содержание строки $Name в любой части строки с названием программы $_.name. Получается что рассматриваемая программа нам подходит если будит выполнено одно из условий, ДО или ПОСЛЕ -or т.е если производитель программы содержит строку $Name или если название программы содержит строку $Name. Результат выборки сохраняем в переменной-массиве $Process
	$Products = Get-WmiObject win32_product | Where-Object {$_.vendor -like "*$Name*" -or $_.name -like "*$Name*"}
	
	# Вывод информации в консоль и в фаил лога с.м. функцию Write-log.	
	Write-log ("`r`n"+"To uninstall:") -Path $LogPath
    
    # Переменная для подсчета общего количества предстоящих к удалению программ. (TODO: Возможно заменить на $Products.Count)
    $TotallToUninstall = 0	

	# В цикле foreach проходимся по каждому объекту-программе из массива $Products
	Foreach ($Product in $Products)
	{
		# Выводим ID программы и ее название в консоль и в лог. Подробнее с.м. функцию Write-log.
		Write-log($Product.IdentifyingNumber + "  -  " + $Product.Name) -Path $LogPath
        $TotallToUninstall++
	}
	
	# Выводим общее количество программ для удаления в консоль и в фаил лога с.м. функцию Write-log.
	Write-log("Total to uninstall : $TotallToUninstall `r`n`r`n"+"Begin uninstalling...") -Path $LogPath

	# Переменная для подсчета петущего номера программы. (TODO: Возможно стоит заменить на цикл foreach на for и использовать итератор для этого.)
	$UninstallCounter = 1	

	# Проходимся циклом по каждой программе из массива $Products
	Foreach ($Product in $Products)
	{
		# Выводим в консоль и в лог информацию в формате : текущее время порядковый номер удаляемой программы / общее кол-во программ - название программы
		Write-log("$UninstallCounter / $TotallToUninstall  -  " + $Product.Name) -TimeStamp	-Path $LogPath

        # Получаем exitcode от функции Uninstall, после удаления msi.
        $exitCode = Uninstall -ID $Product.IdentifyingNumber -Silent:($Silent -or $Verysilent) # Обычно использование параметров типа switch работает так: мы либо передаем его в функцию либо нет т.е. Uninstall -Silent будит значить что Silent == true, если не передаем значит Silent == false 
        # по сути получается такой же bool, только в случае bool'а мы бы были вынуждены писать так: Uninstall -Silent = true, или Uninstall -Silent = false, а если у нас switch можно просто Uninstall -Silent, или просто не передавать его.
        # однако в нашем случае нам нужно передать параметру -Silent ФУНКЦИИ Uninstall результат логической проверки: 
        # если один из параметров СКРИПТА, -Silent или -Verysilent (с.м. шапку скрипта) == true, значит передаем в функцию true, если хотябы один из них == false, значит передаем в функцию false .
        # -Silent:($Silent -or $Verysilent) как раз означает, что мы передаем результат проверки $Silent или $Verysilent СКРИПТА, типа switch, в функцию.

        # Если exitcode 0, значит  все хорошо
        if($exitCode -eq 0) { Write-log ("Successfully uninstalled " + $Product.Name + "`r`n") -Path $LogPath}

        # Если exitcode НЕ 0 пише что все лохо и выводим код
        else { Write-log ("Failed to uninstall " + $Product.Name + ". ExitCode: $exitCode" + "`r`n") -Level Warn -Path $LogPath}

		# Start-Sleep - остановка работы скрипта на 2 секунды, для того что бы msiexec успел завершиться, перестраховка. Ключь -s значит что ждать именно секунды, а не минуты или часы.
		Start-Sleep -s 2
		
        #$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") # ждем ввода пользователя
		
		# Увеличиваем счетчик текущей программы в очереди на удаление на единицу
		$UninstallCounter++
	}	
	# Блок try содержит код, выполнение которого может привести к ошибке и мы об этом знаем (см. блок catch). 
	try
	{
		# Application Manager устанавливается не средствами msi, так что к нему нужен отдельный подход.
		# https://knowledge.autodesk.com/search-result/caas/sfdcarticles/sfdcarticles/How-to-Silently-Uninstall-Application-Manager-using-SCCM.html
		# Для этого пытаемся запустить специальный exe файл, который должен лежать по указанному пути. Ключь запуска --mode unattended должен запустить его в "тихом" режиме. Ну и как всегда WaitForExit() для ожидания завершения работы процесса, перед продолжением.
		[diagnostics.process]::Start("C:\Program Files (x86)\Common Files\Autodesk Shared\AppManager\R1\removeAdAppMgr.exe", "--mode unattended").WaitForExit() 
		
		# Вывод в консоль и в лог информации о том что Application Manager был удален
		Write-log "Autodesk AppManager uninstalled`r`n" -Path $LogPath
	}
	# В блоке catch мы содержим код, который будит выполнен при возникновении ошибки в блоке try
	catch
	{
		# Если removeAdAppMgr.exe найти не удалось - выводим соответствующее соодщение в консоль и в лог.
		Write-log "Can't find Autodesk AppManager`r`n" -Level Warn -Path $LogPath
	}
}


# Удаляет программу по переданному ID
Function Uninstall
{
    Param 
    (
        [Parameter(Mandatory=$true)][string]$ID,      # ID
        [Parameter(Mandatory=$false)][switch]$Silent  # Нужно ли показывать интерфейс при удалении?  
    )

    # Подготовка
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "msiexec"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    
    # Нужен ли тихий режим удаления MSI?
    if($Silent){ $guiARG = " /q" } else{ $guiARG = "" }

    # Аргументы
    $pinfo.Arguments = "/norestart /x " + $ID + $guiARG

    # Запуск процесса
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null

    # Ждем завершения
    $p.WaitForExit()

    # Возвращаем exitcode
    return $p.ExitCode
}


# Функция выводит переданную строку в консоль и пишет ее же в фаил лога.
function Write-Log
{ 
    #$Path = $PSScriptRoot + "C:\AutodeskUninstaller.log"
    Param 
    (
        [Parameter(Mandatory=$true)][string]$Message, # сообщение
        [Parameter(Mandatory=$false)][string]$Path=$PSScriptRoot + "\AutodeskUninstaller.log",
        [Parameter(Mandatory=$false)][ValidateSet("Error","Warn","Ver","Info")][string]$Level="Info", # тип сообщения
        [Parameter(Mandatory=$false)][switch]$TimeStamp # нужно ли показывать время сообщения         
    ) 
    Begin 
    { 
        # Включить/выключить вывод verbose сообщений  
        $VerbosePreference = 'Continue' 
    } 
    Process 
    {   
        
        # Время         
        if($TimeStamp) 
        {
            $FormattedDate = Get-Date -f g
            $FormattedMessage = "$FormattedDate  $Message"
        }
        else
        {
            $FormattedMessage = $Message
        }
        
        # Вывод на экран
        switch ($Level) 
        { 
            'Error' 
            { 
                $FormattedMessage = "ERROR: $FormattedMessage"
                Write-Host $FormattedMessage -ForegroundColor Red 
            } 
            'Warn' 
            { 
                $LevelText = "WARNING: "
                Write-Warning ($FormattedMessage + "`r`n")
            } 
            'Ver' 
            { 
                $LevelText = "VERBOSE: "
                Write-Verbose $FormattedMessage
            }
             'Info' 
            {
                Write-Host $FormattedMessage -ForegroundColor Green
            }  
        } 
        
        # Пишем в фаил
        $LevelText+$FormattedMessage | Out-File -FilePath $Path -Append 
    } 
}


Function ShowLogo()
{

    # https://www.youtube.com/watch?v=5r06heQ5HsI
	Write-log "Jobs Done!`r`n" -TimeStamp -Path $LogPath

    Write-log "
    888     888                     888  
    888     888                     888 
    888     888                     888 
    88888b. 888 .d88b.  .d88b.  .d88888 
    888  88b888d88  88bd88  88bd88  888 
    888  888888888  888888  888888  888 
    888 d88P888Y88..88PY88..88PY88b 888 
    88888P  888  Y88P    Y88P    Y88888 

    88888b.d88b.  .d88b.  .d88b. 88888b.  
    888  888  88bd88  88bd88  88b888  88b 
    888  888  888888  888888  888888  888 
    888  888  888Y88..88PY88..88P888  888 
    888  888  888  Y88P    Y88P  888  888
    " -Path $LogPath

	Start-Sleep -s 6	# Для того чтобы было время заценить мою подпись ^_^ (выше)
}


# Функция выводит сообщение о завершении работы скрипта и перезагружает компьютер
Function ShutdownRTF()
{
	Write-Host "Now restart computer after 10 seconds..." 	# Говорим что компьютер через 10 секунд перезагрузиться
    Start-Sleep -s 10
	cmd.exe /c "shutdown -r -t 10 -f"	# Перезагружаем компьютер используя cmd. 
}


# Глобальный обработчик ошибок
trap
{
    # формат
    $formatstring = "{0}`r`n`{1}`r`n"

    # данные
    $fields = $_.Exception.Message,
              $_.InvocationInfo.PositionMessage
    
    # вывод в консоль и запись в фаил. блягодаря ключьу -f мы выведем данные используя поля из переменной fields, подставив из в {0} и {1} соответственно  
	Write-Log -Message ($formatstring -f $fields) -Level Error -TimeStamp -Path $LogPath

    # продолжить работу скрипта, если это возможно
	Continue
}


# Вызов функции ConsoleSetups, в которой задается размер окна консоли, цвет текста, цвет фона
ConsoleSetups(!$Verysilent)


if($Help) 
{ 
    Get-Help $PSCommandPath -Full
    Read-Host
    exit
}


# Вызов основной функции, которая, в свою очередь, запускает остальные функции-модули.
Run


# Показ подписи автора
ShowLogo


# Если для запуска скрипта использовался параметр Restart...
# Функция выводит сообщение о завершении работы скрипта и перезагружает компьютер
if($Restart) { ShutdownRTF }