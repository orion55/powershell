Echo off
chcp 1251 >nul
set KKTEK=%CD%
set DDIKK=C:\oev\EXG

set KKOTPR=\\main-tseds-01\d$\OBMEN\KBRN\CLI
set KKERR=\\main-tseds-01\d$\OBMEN\KBRN\ERR
set KKRCV=\\main-tseds-01\d$\OBMEN\KBRN\RCV
set KKARCH=ARCH
set DDTT=%date%

xcopy /Y "%KKOTPR%"   CLI
if   %ERRORLEVEL%==1 ( GOTO MOTPRN)
GOTO MOTPR
:MOTPRN
cls
echo Файлов для отправки нет
pause
:MOTPR

xcopy /Y ERR "%KKERR%" 
if   %ERRORLEVEL%==1 ( GOTO MERRN)
GOTO MERR
:MERRN
echo Файлов для ПРИЕМА ERR нет
pause
:MERR

xcopy /Y RCV "%KKRCV%" 
if   %ERRORLEVEL%==1 ( GOTO MRCVN)
GOTO MRCV
:MRCVN
echo Файлов для ПРИЕМА нет
pause
:MRCV
