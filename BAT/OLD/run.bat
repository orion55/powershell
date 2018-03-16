@echo off
set DD=%Date:~0,2%
echo %DD%
echo %1
cd c:\work
arj32 m 288002%DD%.a%1 *.*

