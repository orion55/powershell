@echo off
c:\!\hashfile.exe -p -T c:\!\list.out c:\!\list.prt
if errorlevel 1 goto err
color 7
echo Проверка целостности успешная! Запускаем АРМ.
start c:\uarm3\bin\uarm.exe
goto End
:err
color C
echo Ошибка контроля целостности файлов! АРМ не будет запущен.
pause
exit
:End