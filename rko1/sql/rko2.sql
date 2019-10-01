set lines 360
set pagesize 2000
---set define off;
spool rko.txt
prompt ������� ����� �� ��� 
prompt
prompt
prompt ������ ���� ���������� �������� �� ��� � ������� DD.MM.YYYY
prompt
---def d_beg ='���� ������� ����� �� ���';
--Col "����� �������" Format 999999999999.00
--Col "���.���" Format 9999999
--Col "�����" format 9999999999999999.00
--BREAK ON "����� �������" ON report
--COMPUTE sum OF "����� �������" ON report
---where b.calcdate >= '&d_beg' and b.calcdate <= '&d_end'

select DISTINCT a.divname   "� �/�",
       c.accname "������������ �����",
       c.newaccnum "����� �����",
       b.summa     "����� ��������"
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



