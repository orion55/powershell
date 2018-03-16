set DD=%Date:~0,2%
set GG=%Date:~8,2%
set MM=%Date:~3,2%
echo %DD%
echo %GG%
echo %MM%
c:
cd c:\work
arj32 m AN06962%GG%%MM%%DD%0001 *.*