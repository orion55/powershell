Echo off
rem Копирование с флешки в OEV на отправку и забор принятых
chcp 866 >nul
REM chcp utf8 >nul	
set KKTEK=%CD%
set DDIKK=C:\oev\EXG

set KKOTPR=c:\oev\Exg\cli
set KKERR=c:\oev\Exg\ERR
set KKRCV=c:\oev\Exg\RCV
set KKARCH=ARCH
set DDTT=%date%

copy /Y cli\*.*  "%KKOTPR%"
if   %ERRORLEVEL%==1 ( GOTO MOTPRN)
GOTO MOTPR
:MOTPRN
cls
echo Файлов для отправки нет
pause
:MOTPR

copy /Y "%KKRCV%"  RCV
if   %ERRORLEVEL%==1 (GOTO MRCVN)
move /-Y %KKRCV%\*.* %KKRCV%\ARCH
GOTO MRCV
:MRCVN
echo Файлов для ПРИЕМА нет
pause
:MRCV

copy /Y "%KKERR%"  ERR
if   %ERRORLEVEL%==1 ( GOTO MERRN)
move /-Y %KKERR%\*.* %KKERR%\ARCH
GOTO MERR
:MERRN
echo Файлов для ПРИЕМА ERR нет
pause
:MERR
