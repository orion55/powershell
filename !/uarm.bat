@echo off
c:\!\hashfile.exe -p -T c:\!\list.out c:\!\list.prt
if errorlevel 1 goto err
color 7
echo �஢�ઠ 楫��⭮�� �ᯥ譠�! ����᪠�� ���.
start c:\uarm3\bin\uarm.exe
goto End
:err
color C
echo �訡�� ����஫� 楫��⭮�� 䠩���! ��� �� �㤥� ����饭.
pause
exit
:End