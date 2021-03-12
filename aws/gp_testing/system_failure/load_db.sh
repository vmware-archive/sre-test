for i in {2..15}
do
    nohup psql -c "create table public.tab$i as select * from generate_series (1,20000000);" &
done
