rem %1 MM
rem %2 DD
@echo off
if not exist vo03%1%2.OXA goto end
xcopy vo03%1%2.OXA *.txt /r 
copy vo03%1%2.txt \\tmn-ts-01\binkd\filexchg\moscow\out\vo03%1%2.txt
del vo03%1%2.txt
move vo03%1%2.OXA \\191.168.6.12\quorum\TMN\SENDDOC\BALANS\PROFIT\backup\vo03%1%2.OXA
rem arj m -e b103%2%1 vo03%1%2.OXA
rem copy b103%2%1.arj L:\POST\CLIENT.01\POST\SEND
rem del b103%2%1.arj

rem MAILINI.EXE balance@apkbank.ru L:\POST\CLIENT.01\POST\SEND\b103%2%1.arj b103%2%1.arj	 
rem SendMail
:end
