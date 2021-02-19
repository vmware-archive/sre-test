Step 1
===========

- Create 2 tables with 1 billion rows, distributated randomly.

create table public.tab1 as select * from generate_series (1,1000000000);
create table public.tab2 as select * from generate_series (1,1000000000);

Step 2
=========
- Run below query which will produce the spill

select * from public.tab1 a, public.tab2 b where a.generate_series = b.generate_series;

nohup psql -c "select count(*) from public.tab1 a, public.tab2 b where a.generate_series = b.generate_series;" 2>&1 &
nohup psql -c "select count(*) from public.tab1 a, public.tab2 b where a.generate_series = b.generate_series;" 2>&1 &


Step 3
=========

start load data using tpch script.

nohup sh run.sh &


Step 3
============
- To check the spill.

create view spill_vw as select * from (
        select datname<Plug>PeepOpenid,sess_id,usename,substr(query,0,50),round(max(size/1024/1024/1024)) as max_size_GB, round(min(size/1024/1024/1024)) min_size_GB, round(avg(size/1024/1024/1024)) avg_size_GB, max(numfiles) max_numfiles, count(*) num_of_segmnets
                from gp_toolkit.gp_workfile_usage_per_query
                        group by datname<Plug>PeepOpenid,sess_id,usename,substr(query,0,50)

        ) a
                order by max_size_GB  desc,   max_numfiles desc ;

                        select * from spill_vw;


Step 4
=========
- Once the spill started, we run script to fail primary segment and Recovery from it.

nohup sh kill_primary_pid_spill.sh > kill_primary_pid_spill.log 2>&1 &


