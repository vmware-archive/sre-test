create view spill_vw as
select * from (
select datname, pid,sess_id,usename,substr(query,0,50),round(max(size/1024/1024/1024)) as max_size_GB, round(min(size/1024/1024/1024)) min_size_GB, round(avg(size/1024/1024/1024)) avg_size_GB, max(numfiles) max_numfiles, count(*) num_of_segmnets
from gp_toolkit.gp_workfile_usage_per_query
group by datname, pid,sess_id,usename,substr(query,0,50)

) a
order by max_size_GB desc, max_numfiles desc ;
