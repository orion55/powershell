set DD=%Date:~0,2%
echo %DD%
wftesto.exe s c:\work\%2 c:\work\%2 a:\ 2207 
cd c:\work
arj32 m 288002%DD%.a%1 *.*
cd c:\bat
wftesto.exe e c:\work\288002%DD%.a%1 c:\work\288002%DD%.a%1 a:\ c:\pub 2207 0103
