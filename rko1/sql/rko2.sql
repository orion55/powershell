set lines 360
set pagesize 2000
---set define off;
spool rko.txt
prompt Выборка платы за РКО 
prompt
prompt
prompt Ввести дату начисления комиссии по РКО в формате DD.MM.YYYY
prompt
---def d_beg ='Дата расчета платы за РКО';
--Col "Сумма платежа" Format 999999999999.00
--Col "Ном.док" Format 9999999
--Col "ИТОГО" format 9999999999999999.00
--BREAK ON "Сумма платежа" ON report
--COMPUTE sum OF "Сумма платежа" ON report
---where b.calcdate >= '&d_beg' and b.calcdate <= '&d_end'

select DISTINCT a.divname   "№ Д/О",
       c.accname "Наименование счета",
       c.newaccnum "Номер счета",
       b.summa     "Сумма комиссии"
  from division a, rsperc b, accounts c
 where b.calcdate = to_date('01.10.2019', 'dd.mm.yyyy')
   and c.accnum = b.account
   and c.currcode = '000'
   and b.opernum > 25704
   and a.divcode = c.divcode   
 order by a.divname, c.newaccnum
;
spool off
exit



