set statement_mem='2GB';
select count(*) from (select * from public.tab11 a, public.tab2 b where a.generate_series = b.generate_series) a ;
