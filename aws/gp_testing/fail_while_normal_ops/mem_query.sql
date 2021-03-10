set statement_mem='2GB';
select count(*) from (select * from public.tab2 a, public.tab3 b where a.generate_series = b.generate_series) a ;
