--
-- Greenplum Database database dump
--

SET gp_default_storage_options = '';
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;

--
-- Name: gp_toolkit; Type: SCHEMA; Schema: -; Owner: gpadmin
--

CREATE SCHEMA gp_toolkit;


ALTER SCHEMA gp_toolkit OWNER TO gpadmin;

--
-- Name: __gp_aovisimap_hidden_t; Type: TYPE; Schema: gp_toolkit; Owner: gpadmin
--

CREATE TYPE gp_toolkit.__gp_aovisimap_hidden_t AS (
	seg integer,
	hidden bigint,
	total bigint
);


ALTER TYPE gp_toolkit.__gp_aovisimap_hidden_t OWNER TO gpadmin;

--
-- Name: gp_param_setting_t; Type: TYPE; Schema: gp_toolkit; Owner: gpadmin
--

CREATE TYPE gp_toolkit.gp_param_setting_t AS (
	paramsegment integer,
	paramname text,
	paramvalue text
);


ALTER TYPE gp_toolkit.gp_param_setting_t OWNER TO gpadmin;

--
-- Name: gp_skew_analysis_t; Type: TYPE; Schema: gp_toolkit; Owner: gpadmin
--

CREATE TYPE gp_toolkit.gp_skew_analysis_t AS (
	skewoid oid,
	skewval numeric
);


ALTER TYPE gp_toolkit.gp_skew_analysis_t OWNER TO gpadmin;

--
-- Name: gp_skew_details_t; Type: TYPE; Schema: gp_toolkit; Owner: gpadmin
--

CREATE TYPE gp_toolkit.gp_skew_details_t AS (
	segoid oid,
	segid integer,
	segtupcount bigint
);


ALTER TYPE gp_toolkit.gp_skew_details_t OWNER TO gpadmin;

--
-- Name: __gp_aocsseg(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aocsseg(regclass) RETURNS TABLE(gp_tid tid, segno integer, column_num smallint, physical_segno integer, tupcount bigint, eof bigint, eof_uncompressed bigint, modcount bigint, formatversion smallint, state smallint)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aocsseg_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aocsseg(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aocsseg_history(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) RETURNS TABLE(gp_tid tid, gp_xmin integer, gp_xmin_status text, gp_xmin_distrib_id text, gp_xmax integer, gp_xmax_status text, gp_xmax_distrib_id text, gp_command_id integer, gp_infomask text, gp_update_tid tid, gp_visibility text, segno integer, column_num smallint, physical_segno integer, tupcount bigint, eof bigint, eof_uncompressed bigint, modcount bigint, formatversion smallint, state smallint)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aocsseg_history_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aoseg(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aoseg(regclass) RETURNS TABLE(segno integer, eof bigint, tupcount bigint, varblockcount bigint, eof_uncompressed bigint, modcount bigint, formatversion smallint, state smallint)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aoseg_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aoseg(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aoseg_history(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aoseg_history(regclass) RETURNS TABLE(gp_tid tid, gp_xmin integer, gp_xmin_status text, gp_xmin_commit_distrib_id text, gp_xmax integer, gp_xmax_status text, gp_xmax_commit_distrib_id text, gp_command_id integer, gp_infomask text, gp_update_tid tid, gp_visibility text, segno integer, tupcount bigint, eof bigint, eof_uncompressed bigint, modcount bigint, formatversion smallint, state smallint)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aoseg_history_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aoseg_history(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aovisimap(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aovisimap(regclass) RETURNS TABLE(tid tid, segno integer, row_num bigint)
    LANGUAGE c IMMUTABLE NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aovisimap_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aovisimap(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aovisimap_compaction_info(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aovisimap_compaction_info(ao_oid oid, OUT content integer, OUT datafile integer, OUT compaction_possible boolean, OUT hidden_tupcount bigint, OUT total_tupcount bigint, OUT percent_hidden numeric) RETURNS SETOF record
    LANGUAGE plpgsql NO SQL
    AS $$
DECLARE
    hinfo_row RECORD;
    threshold float;
BEGIN
    EXECUTE 'show gp_appendonly_compaction_threshold' INTO threshold;
    FOR hinfo_row IN SELECT gp_segment_id,
    gp_toolkit.__gp_aovisimap_hidden_typed(ao_oid)::gp_toolkit.__gp_aovisimap_hidden_t
    FROM gp_dist_random('gp_id') LOOP
        content := hinfo_row.gp_segment_id;
        datafile := (hinfo_row.__gp_aovisimap_hidden_typed).seg;
        hidden_tupcount := (hinfo_row.__gp_aovisimap_hidden_typed).hidden;
        total_tupcount := (hinfo_row.__gp_aovisimap_hidden_typed).total;
        compaction_possible := false;
        IF total_tupcount > 0 THEN
            percent_hidden := (100 * hidden_tupcount / total_tupcount::numeric)::numeric(5,2);
        ELSE
            percent_hidden := 0::numeric(5,2);
        END IF;
        IF percent_hidden > threshold THEN
            compaction_possible := true;
        END IF;
        RETURN NEXT;
    END LOOP;
    RAISE NOTICE 'gp_appendonly_compaction_threshold = %', threshold;
    RETURN;
END;
$$;


ALTER FUNCTION gp_toolkit.__gp_aovisimap_compaction_info(ao_oid oid, OUT content integer, OUT datafile integer, OUT compaction_possible boolean, OUT hidden_tupcount bigint, OUT total_tupcount bigint, OUT percent_hidden numeric) OWNER TO gpadmin;

--
-- Name: __gp_aovisimap_entry(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) RETURNS TABLE(segno integer, first_row_num bigint, hidden_tupcount integer, bitmap text)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aovisimap_entry_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aovisimap_hidden_info(regclass); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) RETURNS TABLE(segno integer, hidden_tupcount bigint, total_tupcount bigint)
    LANGUAGE c STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_aovisimap_hidden_info_wrapper';


ALTER FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) OWNER TO gpadmin;

--
-- Name: __gp_aovisimap_hidden_typed(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_aovisimap_hidden_typed(oid) RETURNS SETOF gp_toolkit.__gp_aovisimap_hidden_t
    LANGUAGE sql CONTAINS SQL
    AS $_$
    SELECT * FROM gp_toolkit.__gp_aovisimap_hidden_info($1);
$_$;


ALTER FUNCTION gp_toolkit.__gp_aovisimap_hidden_typed(oid) OWNER TO gpadmin;

--
-- Name: __gp_get_ao_entry_from_cache(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_get_ao_entry_from_cache(ao_oid oid, OUT segno smallint, OUT total_tupcount bigint, OUT tuples_added bigint, OUT inserting_transaction xid, OUT latest_committed_inserting_dxid xid, OUT state smallint, OUT format_version smallint, OUT is_full boolean, OUT aborted boolean) RETURNS SETOF record
    LANGUAGE c IMMUTABLE STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_get_ao_entry_from_cache';


ALTER FUNCTION gp_toolkit.__gp_get_ao_entry_from_cache(ao_oid oid, OUT segno smallint, OUT total_tupcount bigint, OUT tuples_added bigint, OUT inserting_transaction xid, OUT latest_committed_inserting_dxid xid, OUT state smallint, OUT format_version smallint, OUT is_full boolean, OUT aborted boolean) OWNER TO gpadmin;

--
-- Name: __gp_param_setting_on_master(character varying); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) RETURNS SETOF gp_toolkit.gp_param_setting_t
    LANGUAGE sql CONTAINS SQL EXECUTE ON MASTER
    AS $_$
    SELECT gp_execution_segment(), $1, current_setting($1);
$_$;


ALTER FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) OWNER TO gpadmin;

--
-- Name: __gp_param_setting_on_segments(character varying); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) RETURNS SETOF gp_toolkit.gp_param_setting_t
    LANGUAGE sql CONTAINS SQL EXECUTE ON ALL SEGMENTS
    AS $_$
    SELECT gp_execution_segment(), $1, current_setting($1);
$_$;


ALTER FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) OWNER TO gpadmin;

--
-- Name: __gp_remove_ao_entry_from_cache(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_remove_ao_entry_from_cache(oid) RETURNS void
    LANGUAGE c IMMUTABLE STRICT NO SQL
    AS '$libdir/gp_ao_co_diagnostics', 'gp_remove_ao_entry_from_cache';


ALTER FUNCTION gp_toolkit.__gp_remove_ao_entry_from_cache(oid) OWNER TO gpadmin;

--
-- Name: __gp_skew_coefficients(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_skew_coefficients() RETURNS SETOF gp_toolkit.gp_skew_analysis_t
    LANGUAGE plpgsql READS SQL DATA
    AS $$
DECLARE
    skcoid oid;
    skcrec record;

BEGIN
    FOR skcoid IN SELECT autoid from gp_toolkit.__gp_user_data_tables_readable WHERE autrelstorage != 'x'
    LOOP
        SELECT * INTO skcrec
        FROM
            gp_toolkit.gp_skew_coefficient(skcoid);
        RETURN NEXT skcrec;
    END LOOP;
END
$$;


ALTER FUNCTION gp_toolkit.__gp_skew_coefficients() OWNER TO gpadmin;

--
-- Name: __gp_skew_idle_fractions(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_skew_idle_fractions() RETURNS SETOF gp_toolkit.gp_skew_analysis_t
    LANGUAGE plpgsql READS SQL DATA
    AS $$
DECLARE
    skcoid oid;
    skcrec record;

BEGIN
    FOR skcoid IN SELECT autoid from gp_toolkit.__gp_user_data_tables_readable WHERE autrelstorage != 'x'
    LOOP
        SELECT * INTO skcrec
        FROM
            gp_toolkit.gp_skew_idle_fraction(skcoid);
        RETURN NEXT skcrec;
    END LOOP;
END
$$;


ALTER FUNCTION gp_toolkit.__gp_skew_idle_fractions() OWNER TO gpadmin;

--
-- Name: __gp_workfile_entries_f_on_master(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() RETURNS SETOF record
    LANGUAGE c NO SQL EXECUTE ON MASTER
    AS '$libdir/gp_workfile_mgr', 'gp_workfile_mgr_cache_entries';


ALTER FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() OWNER TO gpadmin;

--
-- Name: __gp_workfile_entries_f_on_segments(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() RETURNS SETOF record
    LANGUAGE c NO SQL EXECUTE ON ALL SEGMENTS
    AS '$libdir/gp_workfile_mgr', 'gp_workfile_mgr_cache_entries';


ALTER FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() OWNER TO gpadmin;

--
-- Name: __gp_workfile_mgr_used_diskspace_f_on_master(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() RETURNS SETOF record
    LANGUAGE c NO SQL EXECUTE ON MASTER
    AS '$libdir/gp_workfile_mgr', 'gp_workfile_mgr_used_diskspace';


ALTER FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() OWNER TO gpadmin;

--
-- Name: __gp_workfile_mgr_used_diskspace_f_on_segments(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() RETURNS SETOF record
    LANGUAGE c NO SQL EXECUTE ON ALL SEGMENTS
    AS '$libdir/gp_workfile_mgr', 'gp_workfile_mgr_used_diskspace';


ALTER FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() OWNER TO gpadmin;

--
-- Name: gp_bloat_diag(integer, numeric, boolean); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) RETURNS record
    LANGUAGE sql READS SQL DATA
    AS $_$
    SELECT
        bloatidx,
        CASE
            WHEN bloatidx = 0
                THEN 'no bloat detected'::text
            WHEN bloatidx = 1
                THEN 'moderate amount of bloat suspected'::text
            WHEN bloatidx = 2
                THEN 'significant amount of bloat suspected'::text
            WHEN bloatidx = -1
                THEN 'diagnosis inconclusive or no bloat suspected'::text
        END AS bloatdiag
    FROM
    (
        SELECT
            CASE
                WHEN $3 = 't' THEN 0
                WHEN $1 < 10 AND $2 = 0 THEN -1
                WHEN $2 = 0 THEN 2
                WHEN $1 < $2 THEN 0
                WHEN ($1/$2)::numeric > 10 THEN 2
                WHEN ($1/$2)::numeric > 3 THEN 1
                ELSE -1
            END AS bloatidx
    ) AS bloatmapping

$_$;


ALTER FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) OWNER TO gpadmin;

--
-- Name: gp_param_setting(character varying); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_param_setting(character varying) RETURNS SETOF gp_toolkit.gp_param_setting_t
    LANGUAGE sql READS SQL DATA EXECUTE ON MASTER
    AS $_$
  SELECT * FROM gp_toolkit.__gp_param_setting_on_master($1)
  UNION ALL
  SELECT * FROM gp_toolkit.__gp_param_setting_on_segments($1);
$_$;


ALTER FUNCTION gp_toolkit.gp_param_setting(character varying) OWNER TO gpadmin;

--
-- Name: gp_param_settings(); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_param_settings() RETURNS SETOF gp_toolkit.gp_param_setting_t
    LANGUAGE sql READS SQL DATA EXECUTE ON ALL SEGMENTS
    AS $$
    select gp_execution_segment(), name, setting from pg_settings;
$$;


ALTER FUNCTION gp_toolkit.gp_param_settings() OWNER TO gpadmin;

--
-- Name: gp_skew_coefficient(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) RETURNS record
    LANGUAGE sql READS SQL DATA
    AS $_$
    SELECT
        $1 as skcoid,
        CASE
            WHEN skewmean > 0 THEN ((skewdev/skewmean) * 100.0)
            ELSE 0
        END
        AS skccoeff
    FROM
    (
        SELECT STDDEV(segtupcount) AS skewdev, AVG(segtupcount) AS skewmean, COUNT(*) AS skewcnt
        FROM gp_toolkit.gp_skew_details($1)
    ) AS skew

$_$;


ALTER FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) OWNER TO gpadmin;

--
-- Name: gp_skew_details(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_skew_details(oid) RETURNS SETOF gp_toolkit.gp_skew_details_t
    LANGUAGE plpgsql READS SQL DATA
    AS $_$
DECLARE
    skewcrs refcursor;
    skewrec record;
    skewarray bigint[];
    skewaot bool;
    skewsegid int;
    skewtablename record;
    skewreplicated record;

BEGIN

    SELECT INTO skewrec *
    FROM pg_catalog.pg_appendonly pga, pg_catalog.pg_roles pgr
    WHERE pga.relid = $1::regclass and pgr.rolname = current_user and pgr.rolsuper = 't';

    IF FOUND THEN
        -- append only table

        FOR skewrec IN
            SELECT $1, segid, COALESCE(tupcount, 0)::bigint AS cnt
            FROM (SELECT generate_series(0, numsegments - 1) FROM gp_toolkit.__gp_number_of_segments) segs(segid)
            LEFT OUTER JOIN pg_catalog.get_ao_distribution($1)
            ON segid = segmentid
        LOOP
            RETURN NEXT skewrec;
        END LOOP;

    ELSE
        -- heap table

        SELECT * INTO skewtablename FROM gp_toolkit.__gp_fullname
        WHERE fnoid = $1;

        SELECT * INTO skewreplicated FROM gp_distribution_policy WHERE policytype = 'r' AND localoid = $1;

        IF FOUND THEN
            -- replicated table, gp_segment_id is user-invisible and all replicas have same count of tuples.
            OPEN skewcrs
                FOR
                EXECUTE
                    'SELECT ' || $1 || '::oid, segid, ' ||
                    '(' ||
                        'SELECT COUNT(*) AS cnt FROM ' ||
                        quote_ident(skewtablename.fnnspname) ||
                        '.' ||
                        quote_ident(skewtablename.fnrelname) ||
                    ') '
                    'FROM (SELECT generate_series(0, numsegments - 1) FROM gp_toolkit.__gp_number_of_segments) segs(segid)';
        ELSE
            OPEN skewcrs
                FOR
                EXECUTE
                    'SELECT ' || $1 || '::oid, segid, CASE WHEN gp_segment_id IS NULL THEN 0 ELSE cnt END ' ||
                    'FROM (SELECT generate_series(0, numsegments - 1) FROM gp_toolkit.__gp_number_of_segments) segs(segid) ' ||
                    'LEFT OUTER JOIN ' ||
                        '(SELECT gp_segment_id, COUNT(*) AS cnt FROM ' ||
                            quote_ident(skewtablename.fnnspname) ||
                            '.' ||
                            quote_ident(skewtablename.fnrelname) ||
                        ' GROUP BY 1) details ' ||
                    'ON segid = gp_segment_id';
        END IF;

        FOR skewsegid IN
            SELECT generate_series(1, numsegments)
            FROM gp_toolkit.__gp_number_of_segments
        LOOP
            FETCH skewcrs INTO skewrec;
            IF FOUND THEN
                RETURN NEXT skewrec;
            ELSE
                RETURN;
            END IF;
        END LOOP;
        CLOSE skewcrs;
    END IF;

    RETURN;
END
$_$;


ALTER FUNCTION gp_toolkit.gp_skew_details(oid) OWNER TO gpadmin;

--
-- Name: gp_skew_idle_fraction(oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) RETURNS record
    LANGUAGE sql READS SQL DATA
    AS $_$
    SELECT
        $1 as sifoid,
        CASE
            WHEN MIN(skewmax) = 0 THEN 0
            ELSE (SUM(skewmax - segtupcount) / (MIN(skewmax) * MIN(numsegments)))
        END
        AS siffraction
    FROM
    (
        SELECT segid, segtupcount, COUNT(segid) OVER () AS numsegments, MAX(segtupcount) OVER () AS skewmax
        FROM gp_toolkit.gp_skew_details($1)
    ) AS skewbaseline

$_$;


ALTER FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) OWNER TO gpadmin;

--
-- Name: pg_resgroup_check_move_query(integer, oid); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) RETURNS SETOF record
    LANGUAGE c NO SQL
    AS 'gp_resource_group', 'pg_resgroup_check_move_query';


ALTER FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) OWNER TO gpadmin;

--
-- Name: pg_resgroup_move_query(integer, text); Type: FUNCTION; Schema: gp_toolkit; Owner: gpadmin
--

CREATE FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) RETURNS boolean
    LANGUAGE c NO SQL
    AS 'gp_resource_group', 'pg_resgroup_move_query';


ALTER FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) OWNER TO gpadmin;

--
-- Name: __gp_fullname; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_fullname AS
 SELECT pgc.oid AS fnoid,
    pgn.nspname AS fnnspname,
    pgc.relname AS fnrelname
   FROM pg_class pgc,
    pg_namespace pgn
  WHERE (pgc.relnamespace = pgn.oid);


ALTER TABLE gp_toolkit.__gp_fullname OWNER TO gpadmin;

--
-- Name: __gp_is_append_only; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_is_append_only AS
 SELECT pgc.oid AS iaooid,
        CASE
            WHEN (pgao.relid IS NULL) THEN false
            ELSE true
        END AS iaotype
   FROM (pg_class pgc
     LEFT JOIN pg_appendonly pgao ON ((pgc.oid = pgao.relid)));


ALTER TABLE gp_toolkit.__gp_is_append_only OWNER TO gpadmin;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: __gp_log_master_ext; Type: EXTERNAL TABLE; Schema: gp_toolkit; Owner: gpadmin; Tablespace: 
--

CREATE EXTERNAL WEB TABLE gp_toolkit.__gp_log_master_ext (
    logtime timestamp with time zone,
    loguser text,
    logdatabase text,
    logpid text,
    logthread text,
    loghost text,
    logport text,
    logsessiontime timestamp with time zone,
    logtransaction integer,
    logsession text,
    logcmdcount text,
    logsegment text,
    logslice text,
    logdistxact text,
    loglocalxact text,
    logsubxact text,
    logseverity text,
    logstate text,
    logmessage text,
    logdetail text,
    loghint text,
    logquery text,
    logquerypos integer,
    logcontext text,
    logdebug text,
    logcursorpos integer,
    logfunction text,
    logfile text,
    logline integer,
    logstack text
) EXECUTE E'cat $GP_SEG_DATADIR/pg_log/*.csv' ON MASTER 
FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8';


ALTER EXTERNAL TABLE gp_toolkit.__gp_log_master_ext OWNER TO gpadmin;

--
-- Name: __gp_log_segment_ext; Type: EXTERNAL TABLE; Schema: gp_toolkit; Owner: gpadmin; Tablespace: 
--

CREATE EXTERNAL WEB TABLE gp_toolkit.__gp_log_segment_ext (
    logtime timestamp with time zone,
    loguser text,
    logdatabase text,
    logpid text,
    logthread text,
    loghost text,
    logport text,
    logsessiontime timestamp with time zone,
    logtransaction integer,
    logsession text,
    logcmdcount text,
    logsegment text,
    logslice text,
    logdistxact text,
    loglocalxact text,
    logsubxact text,
    logseverity text,
    logstate text,
    logmessage text,
    logdetail text,
    loghint text,
    logquery text,
    logquerypos integer,
    logcontext text,
    logdebug text,
    logcursorpos integer,
    logfunction text,
    logfile text,
    logline integer,
    logstack text
) EXECUTE E'cat $GP_SEG_DATADIR/pg_log/*.csv' ON ALL 
FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8';


ALTER EXTERNAL TABLE gp_toolkit.__gp_log_segment_ext OWNER TO gpadmin;

--
-- Name: __gp_number_of_segments; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_number_of_segments AS
 SELECT (count(*))::smallint AS numsegments
   FROM gp_segment_configuration
  WHERE ((gp_segment_configuration.preferred_role = 'p'::"char") AND (gp_segment_configuration.content >= 0));


ALTER TABLE gp_toolkit.__gp_number_of_segments OWNER TO gpadmin;

--
-- Name: __gp_user_namespaces; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_user_namespaces AS
 SELECT pg_namespace.oid AS aunoid,
    pg_namespace.nspname AS aunnspname
   FROM pg_namespace
  WHERE (((pg_namespace.nspname !~~ 'pg_%'::text) AND (pg_namespace.nspname <> 'gp_toolkit'::name)) AND (pg_namespace.nspname <> 'information_schema'::name));


ALTER TABLE gp_toolkit.__gp_user_namespaces OWNER TO gpadmin;

--
-- Name: __gp_user_tables; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_user_tables AS
 SELECT fn.fnnspname AS autnspname,
    fn.fnrelname AS autrelname,
    pgc.relkind AS autrelkind,
    pgc.reltuples AS autreltuples,
    pgc.relpages AS autrelpages,
    pgc.relacl AS autrelacl,
    pgc.oid AS autoid,
    pgc.reltoastrelid AS auttoastoid,
    pgc.relstorage AS autrelstorage
   FROM pg_class pgc,
    gp_toolkit.__gp_fullname fn
  WHERE (((pgc.relnamespace IN ( SELECT __gp_user_namespaces.aunoid
           FROM gp_toolkit.__gp_user_namespaces)) AND (pgc.relkind = 'r'::"char")) AND (pgc.oid = fn.fnoid));


ALTER TABLE gp_toolkit.__gp_user_tables OWNER TO gpadmin;

--
-- Name: __gp_user_data_tables; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_user_data_tables AS
 SELECT aut.autnspname,
    aut.autrelname,
    aut.autrelkind,
    aut.autreltuples,
    aut.autrelpages,
    aut.autrelacl,
    aut.autoid,
    aut.auttoastoid,
    aut.autrelstorage
   FROM (gp_toolkit.__gp_user_tables aut
     LEFT JOIN pg_partition pgp ON ((aut.autoid = pgp.parrelid)))
  WHERE (pgp.parrelid IS NULL);


ALTER TABLE gp_toolkit.__gp_user_data_tables OWNER TO gpadmin;

--
-- Name: __gp_user_data_tables_readable; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.__gp_user_data_tables_readable AS
 SELECT aut.autnspname,
    aut.autrelname,
    aut.autrelkind,
    aut.autreltuples,
    aut.autrelpages,
    aut.autrelacl,
    aut.autoid,
    aut.auttoastoid,
    aut.autrelstorage
   FROM gp_toolkit.__gp_user_tables aut
  WHERE has_table_privilege(aut.autoid, 'select'::text);


ALTER TABLE gp_toolkit.__gp_user_data_tables_readable OWNER TO gpadmin;

--
-- Name: gp_bloat_expected_pages; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_bloat_expected_pages AS
 SELECT subq.btdrelid,
    subq.btdrelpages,
        CASE
            WHEN (subq.btdexppages < (subq.numsegments)::numeric) THEN (subq.numsegments)::numeric
            ELSE subq.btdexppages
        END AS btdexppages
   FROM ( SELECT pgc.oid AS btdrelid,
            pgc.relpages AS btdrelpages,
            ceil((((pgc.reltuples * ((25)::double precision + btwcols.width)))::numeric / (current_setting('block_size'::text))::numeric)) AS btdexppages,
            ( SELECT __gp_number_of_segments.numsegments
                   FROM gp_toolkit.__gp_number_of_segments) AS numsegments
           FROM (( SELECT pgc_1.oid,
                    pgc_1.reltuples,
                    pgc_1.relpages
                   FROM pg_class pgc_1
                  WHERE ((NOT (EXISTS ( SELECT __gp_is_append_only.iaooid
                           FROM gp_toolkit.__gp_is_append_only
                          WHERE ((__gp_is_append_only.iaooid = pgc_1.oid) AND (__gp_is_append_only.iaotype = true))))) AND (NOT (EXISTS ( SELECT pg_partition.parrelid
                           FROM pg_partition
                          WHERE (pg_partition.parrelid = pgc_1.oid)))))) pgc
             LEFT JOIN ( SELECT pgs.starelid,
                    sum(((pgs.stawidth)::double precision * ((1.0)::double precision - pgs.stanullfrac))) AS width
                   FROM pg_statistic pgs
                  GROUP BY pgs.starelid) btwcols ON ((pgc.oid = btwcols.starelid)))
          WHERE (btwcols.starelid IS NOT NULL)) subq;


ALTER TABLE gp_toolkit.gp_bloat_expected_pages OWNER TO gpadmin;

--
-- Name: gp_bloat_diag; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_bloat_diag AS
 SELECT bloatsummary.btdrelid AS bdirelid,
    bloatsummary.fnnspname AS bdinspname,
    bloatsummary.fnrelname AS bdirelname,
    bloatsummary.btdrelpages AS bdirelpages,
    bloatsummary.btdexppages AS bdiexppages,
    (bloatsummary.bd).bltdiag AS bdidiag
   FROM ( SELECT fn.fnoid,
            fn.fnnspname,
            fn.fnrelname,
            beg.btdrelid,
            beg.btdrelpages,
            beg.btdexppages,
            gp_toolkit.gp_bloat_diag(beg.btdrelpages, beg.btdexppages, iao.iaotype) AS bd
           FROM gp_toolkit.gp_bloat_expected_pages beg,
            pg_class pgc,
            gp_toolkit.__gp_fullname fn,
            gp_toolkit.__gp_is_append_only iao
          WHERE (((beg.btdrelid = pgc.oid) AND (pgc.oid = fn.fnoid)) AND (iao.iaooid = pgc.oid))) bloatsummary
  WHERE ((bloatsummary.bd).bltidx > 0);


ALTER TABLE gp_toolkit.gp_bloat_diag OWNER TO gpadmin;

--
-- Name: gp_disk_free; Type: EXTERNAL TABLE; Schema: gp_toolkit; Owner: gpadmin; Tablespace: 
--

CREATE EXTERNAL WEB TABLE gp_toolkit.gp_disk_free (
    dfsegment integer,
    dfhostname text,
    dfdevice text,
    dfspace bigint
) EXECUTE E'python -c "from gppylib.commands import unix; df=unix.DiskFree.get_disk_free_info_local(\'token\',\'$GP_SEG_DATADIR\'); print \'%s, %s, %s, %s\' % (\'$GP_SEGMENT_ID\', unix.getLocalHostname(), df[0], df[3])"' ON ALL 
FORMAT 'csv' (delimiter E',' null E'' escape E'"' quote E'"')
ENCODING 'UTF8';


ALTER EXTERNAL TABLE gp_toolkit.gp_disk_free OWNER TO gpadmin;

--
-- Name: gp_locks_on_relation; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_locks_on_relation AS
 SELECT pgl.locktype AS lorlocktype,
    pgl.database AS lordatabase,
    pgc.relname AS lorrelname,
    pgl.relation AS lorrelation,
    pgl.transactionid AS lortransaction,
    pgl.pid AS lorpid,
    pgl.mode AS lormode,
    pgl.granted AS lorgranted,
    pgsa.query AS lorcurrentquery
   FROM ((pg_locks pgl
     JOIN pg_class pgc ON ((pgl.relation = pgc.oid)))
     JOIN pg_stat_activity pgsa ON ((pgl.pid = pgsa.pid)))
  ORDER BY pgc.relname;


ALTER TABLE gp_toolkit.gp_locks_on_relation OWNER TO gpadmin;

--
-- Name: gp_locks_on_resqueue; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_locks_on_resqueue AS
 SELECT pgsa.usename AS lorusename,
    pgrq.rsqname AS lorrsqname,
    pgl.locktype AS lorlocktype,
    pgl.objid AS lorobjid,
    pgl.transactionid AS lortransaction,
    pgl.pid AS lorpid,
    pgl.mode AS lormode,
    pgl.granted AS lorgranted,
    pgsa.waiting AS lorwaiting
   FROM ((pg_stat_activity pgsa
     JOIN pg_locks pgl ON ((pgsa.pid = pgl.pid)))
     JOIN pg_resqueue pgrq ON ((pgl.objid = pgrq.oid)));


ALTER TABLE gp_toolkit.gp_locks_on_resqueue OWNER TO gpadmin;

--
-- Name: gp_log_command_timings; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_log_command_timings AS
 SELECT __gp_log_master_ext.logsession,
    __gp_log_master_ext.logcmdcount,
    __gp_log_master_ext.logdatabase,
    __gp_log_master_ext.loguser,
    __gp_log_master_ext.logpid,
    min(__gp_log_master_ext.logtime) AS logtimemin,
    max(__gp_log_master_ext.logtime) AS logtimemax,
    (max(__gp_log_master_ext.logtime) - min(__gp_log_master_ext.logtime)) AS logduration
   FROM gp_toolkit.__gp_log_master_ext
  WHERE (((__gp_log_master_ext.logsession IS NOT NULL) AND (__gp_log_master_ext.logcmdcount IS NOT NULL)) AND (__gp_log_master_ext.logdatabase IS NOT NULL))
  GROUP BY __gp_log_master_ext.logsession, __gp_log_master_ext.logcmdcount, __gp_log_master_ext.logdatabase, __gp_log_master_ext.loguser, __gp_log_master_ext.logpid;


ALTER TABLE gp_toolkit.gp_log_command_timings OWNER TO gpadmin;

--
-- Name: gp_log_system; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_log_system AS
 SELECT __gp_log_segment_ext.logtime,
    __gp_log_segment_ext.loguser,
    __gp_log_segment_ext.logdatabase,
    __gp_log_segment_ext.logpid,
    __gp_log_segment_ext.logthread,
    __gp_log_segment_ext.loghost,
    __gp_log_segment_ext.logport,
    __gp_log_segment_ext.logsessiontime,
    __gp_log_segment_ext.logtransaction,
    __gp_log_segment_ext.logsession,
    __gp_log_segment_ext.logcmdcount,
    __gp_log_segment_ext.logsegment,
    __gp_log_segment_ext.logslice,
    __gp_log_segment_ext.logdistxact,
    __gp_log_segment_ext.loglocalxact,
    __gp_log_segment_ext.logsubxact,
    __gp_log_segment_ext.logseverity,
    __gp_log_segment_ext.logstate,
    __gp_log_segment_ext.logmessage,
    __gp_log_segment_ext.logdetail,
    __gp_log_segment_ext.loghint,
    __gp_log_segment_ext.logquery,
    __gp_log_segment_ext.logquerypos,
    __gp_log_segment_ext.logcontext,
    __gp_log_segment_ext.logdebug,
    __gp_log_segment_ext.logcursorpos,
    __gp_log_segment_ext.logfunction,
    __gp_log_segment_ext.logfile,
    __gp_log_segment_ext.logline,
    __gp_log_segment_ext.logstack
   FROM gp_toolkit.__gp_log_segment_ext
UNION ALL
 SELECT __gp_log_master_ext.logtime,
    __gp_log_master_ext.loguser,
    __gp_log_master_ext.logdatabase,
    __gp_log_master_ext.logpid,
    __gp_log_master_ext.logthread,
    __gp_log_master_ext.loghost,
    __gp_log_master_ext.logport,
    __gp_log_master_ext.logsessiontime,
    __gp_log_master_ext.logtransaction,
    __gp_log_master_ext.logsession,
    __gp_log_master_ext.logcmdcount,
    __gp_log_master_ext.logsegment,
    __gp_log_master_ext.logslice,
    __gp_log_master_ext.logdistxact,
    __gp_log_master_ext.loglocalxact,
    __gp_log_master_ext.logsubxact,
    __gp_log_master_ext.logseverity,
    __gp_log_master_ext.logstate,
    __gp_log_master_ext.logmessage,
    __gp_log_master_ext.logdetail,
    __gp_log_master_ext.loghint,
    __gp_log_master_ext.logquery,
    __gp_log_master_ext.logquerypos,
    __gp_log_master_ext.logcontext,
    __gp_log_master_ext.logdebug,
    __gp_log_master_ext.logcursorpos,
    __gp_log_master_ext.logfunction,
    __gp_log_master_ext.logfile,
    __gp_log_master_ext.logline,
    __gp_log_master_ext.logstack
   FROM gp_toolkit.__gp_log_master_ext
  ORDER BY 1;


ALTER TABLE gp_toolkit.gp_log_system OWNER TO gpadmin;

--
-- Name: gp_log_database; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_log_database AS
 SELECT gp_log_system.logtime,
    gp_log_system.loguser,
    gp_log_system.logdatabase,
    gp_log_system.logpid,
    gp_log_system.logthread,
    gp_log_system.loghost,
    gp_log_system.logport,
    gp_log_system.logsessiontime,
    gp_log_system.logtransaction,
    gp_log_system.logsession,
    gp_log_system.logcmdcount,
    gp_log_system.logsegment,
    gp_log_system.logslice,
    gp_log_system.logdistxact,
    gp_log_system.loglocalxact,
    gp_log_system.logsubxact,
    gp_log_system.logseverity,
    gp_log_system.logstate,
    gp_log_system.logmessage,
    gp_log_system.logdetail,
    gp_log_system.loghint,
    gp_log_system.logquery,
    gp_log_system.logquerypos,
    gp_log_system.logcontext,
    gp_log_system.logdebug,
    gp_log_system.logcursorpos,
    gp_log_system.logfunction,
    gp_log_system.logfile,
    gp_log_system.logline,
    gp_log_system.logstack
   FROM gp_toolkit.gp_log_system
  WHERE (gp_log_system.logdatabase = (current_database())::text);


ALTER TABLE gp_toolkit.gp_log_database OWNER TO gpadmin;

--
-- Name: gp_log_master_concise; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_log_master_concise AS
 SELECT __gp_log_master_ext.logtime,
    __gp_log_master_ext.logdatabase,
    __gp_log_master_ext.logsession,
    __gp_log_master_ext.logcmdcount,
    __gp_log_master_ext.logseverity,
    __gp_log_master_ext.logmessage
   FROM gp_toolkit.__gp_log_master_ext;


ALTER TABLE gp_toolkit.gp_log_master_concise OWNER TO gpadmin;

--
-- Name: gp_param_settings_seg_value_diffs; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_param_settings_seg_value_diffs AS
 SELECT gp_param_settings.paramname AS psdname,
    gp_param_settings.paramvalue AS psdvalue,
    count(*) AS psdcount
   FROM gp_toolkit.gp_param_settings() gp_param_settings(paramsegment, paramname, paramvalue)
  WHERE (gp_param_settings.paramname <> ALL (ARRAY['config_file'::text, 'data_directory'::text, 'gp_contentid'::text, 'gp_dbid'::text, 'hba_file'::text, 'ident_file'::text, 'port'::text]))
  GROUP BY gp_param_settings.paramname, gp_param_settings.paramvalue
 HAVING (count(*) < ( SELECT __gp_number_of_segments.numsegments
           FROM gp_toolkit.__gp_number_of_segments))
  ORDER BY gp_param_settings.paramname, gp_param_settings.paramvalue, count(*);


ALTER TABLE gp_toolkit.gp_param_settings_seg_value_diffs OWNER TO gpadmin;

--
-- Name: gp_pgdatabase_invalid; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_pgdatabase_invalid AS
 SELECT gp_pgdatabase.dbid AS pgdbidbid,
    gp_pgdatabase.isprimary AS pgdbiisprimary,
    gp_pgdatabase.content AS pgdbicontent,
    gp_pgdatabase.valid AS pgdbivalid,
    gp_pgdatabase.definedprimary AS pgdbidefinedprimary
   FROM gp_pgdatabase
  WHERE (NOT gp_pgdatabase.valid)
  ORDER BY gp_pgdatabase.dbid;


ALTER TABLE gp_toolkit.gp_pgdatabase_invalid OWNER TO gpadmin;

--
-- Name: gp_resgroup_config; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resgroup_config AS
 SELECT g.oid AS groupid,
    g.rsgname AS groupname,
    t1.value AS concurrency,
    t2.value AS cpu_rate_limit,
    t3.value AS memory_limit,
    t4.value AS memory_shared_quota,
    t5.value AS memory_spill_ratio,
        CASE
            WHEN (t6.value IS NULL) THEN 'vmtracker'::text
            WHEN (t6.value = '0'::text) THEN 'vmtracker'::text
            WHEN (t6.value = '1'::text) THEN 'cgroup'::text
            ELSE 'unknown'::text
        END AS memory_auditor,
    t7.value AS cpuset
   FROM (((((((pg_resgroup g
     JOIN pg_resgroupcapability t1 ON (((g.oid = t1.resgroupid) AND (t1.reslimittype = 1))))
     JOIN pg_resgroupcapability t2 ON (((g.oid = t2.resgroupid) AND (t2.reslimittype = 2))))
     JOIN pg_resgroupcapability t3 ON (((g.oid = t3.resgroupid) AND (t3.reslimittype = 3))))
     JOIN pg_resgroupcapability t4 ON (((g.oid = t4.resgroupid) AND (t4.reslimittype = 4))))
     JOIN pg_resgroupcapability t5 ON (((g.oid = t5.resgroupid) AND (t5.reslimittype = 5))))
     LEFT JOIN pg_resgroupcapability t6 ON (((g.oid = t6.resgroupid) AND (t6.reslimittype = 6))))
     LEFT JOIN pg_resgroupcapability t7 ON (((g.oid = t7.resgroupid) AND (t7.reslimittype = 7))));


ALTER TABLE gp_toolkit.gp_resgroup_config OWNER TO gpadmin;

--
-- Name: gp_resgroup_status; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resgroup_status AS
 SELECT r.rsgname,
    s.groupid,
    s.num_running,
    s.num_queueing,
    s.num_queued,
    s.num_executed,
    s.total_queue_duration,
    s.cpu_usage,
    s.memory_usage
   FROM pg_resgroup_get_status(NULL::oid) s(groupid, num_running, num_queueing, num_queued, num_executed, total_queue_duration, cpu_usage, memory_usage),
    pg_resgroup r
  WHERE (s.groupid = r.oid);


ALTER TABLE gp_toolkit.gp_resgroup_status OWNER TO gpadmin;

--
-- Name: gp_resgroup_status_per_host; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resgroup_status_per_host AS
 WITH s AS (
         SELECT gp_resgroup_status.rsgname,
            gp_resgroup_status.groupid,
            ((json_each(gp_resgroup_status.cpu_usage)).key)::smallint AS segment_id,
            (json_each(gp_resgroup_status.cpu_usage)).value AS cpu,
            (json_each(gp_resgroup_status.memory_usage)).value AS memory
           FROM gp_toolkit.gp_resgroup_status
        )
 SELECT s.rsgname,
    s.groupid,
    c.hostname,
    round(avg(((s.cpu)::text)::numeric), 2) AS cpu,
    sum((((s.memory -> 'used'::text))::text)::integer) AS memory_used,
    sum((((s.memory -> 'available'::text))::text)::integer) AS memory_available,
    sum((((s.memory -> 'quota_used'::text))::text)::integer) AS memory_quota_used,
    sum((((s.memory -> 'quota_available'::text))::text)::integer) AS memory_quota_available,
    sum((((s.memory -> 'shared_used'::text))::text)::integer) AS memory_shared_used,
    sum((((s.memory -> 'shared_available'::text))::text)::integer) AS memory_shared_available
   FROM (s
     JOIN gp_segment_configuration c ON (((s.segment_id = c.content) AND (c.role = 'p'::"char"))))
  GROUP BY s.rsgname, s.groupid, c.hostname;


ALTER TABLE gp_toolkit.gp_resgroup_status_per_host OWNER TO gpadmin;

--
-- Name: gp_resgroup_status_per_segment; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resgroup_status_per_segment AS
 WITH s AS (
         SELECT gp_resgroup_status.rsgname,
            gp_resgroup_status.groupid,
            ((json_each(gp_resgroup_status.cpu_usage)).key)::smallint AS segment_id,
            (json_each(gp_resgroup_status.cpu_usage)).value AS cpu,
            (json_each(gp_resgroup_status.memory_usage)).value AS memory
           FROM gp_toolkit.gp_resgroup_status
        )
 SELECT s.rsgname,
    s.groupid,
    c.hostname,
    s.segment_id,
    sum(((s.cpu)::text)::numeric) AS cpu,
    sum((((s.memory -> 'used'::text))::text)::integer) AS memory_used,
    sum((((s.memory -> 'available'::text))::text)::integer) AS memory_available,
    sum((((s.memory -> 'quota_used'::text))::text)::integer) AS memory_quota_used,
    sum((((s.memory -> 'quota_available'::text))::text)::integer) AS memory_quota_available,
    sum((((s.memory -> 'shared_used'::text))::text)::integer) AS memory_shared_used,
    sum((((s.memory -> 'shared_available'::text))::text)::integer) AS memory_shared_available
   FROM (s
     JOIN gp_segment_configuration c ON (((s.segment_id = c.content) AND (c.role = 'p'::"char"))))
  GROUP BY s.rsgname, s.groupid, c.hostname, s.segment_id;


ALTER TABLE gp_toolkit.gp_resgroup_status_per_segment OWNER TO gpadmin;

--
-- Name: gp_resq_activity; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resq_activity AS
 SELECT psa.pid AS resqprocpid,
    psa.usename AS resqrole,
    resq.resqoid,
    resq.rsqname AS resqname,
    psa.query_start AS resqstart,
        CASE
            WHEN (resq.resqgranted = false) THEN 'waiting'::text
            ELSE 'running'::text
        END AS resqstatus
   FROM (pg_stat_activity psa
     JOIN ( SELECT pgrq.oid AS resqoid,
            pgrq.rsqname,
            pgl.pid AS resqprocid,
            pgl.granted AS resqgranted
           FROM pg_resqueue pgrq,
            pg_locks pgl
          WHERE (pgl.objid = pgrq.oid)) resq ON ((resq.resqprocid = psa.pid)))
  WHERE (psa.query <> '<IDLE>'::text)
  ORDER BY psa.query_start;


ALTER TABLE gp_toolkit.gp_resq_activity OWNER TO gpadmin;

--
-- Name: gp_resq_activity_by_queue; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resq_activity_by_queue AS
 SELECT gp_resq_activity.resqoid,
    gp_resq_activity.resqname,
    max(gp_resq_activity.resqstart) AS resqlast,
    gp_resq_activity.resqstatus,
    count(*) AS resqtotal
   FROM gp_toolkit.gp_resq_activity
  GROUP BY gp_resq_activity.resqoid, gp_resq_activity.resqname, gp_resq_activity.resqstatus
  ORDER BY gp_resq_activity.resqoid, max(gp_resq_activity.resqstart);


ALTER TABLE gp_toolkit.gp_resq_activity_by_queue OWNER TO gpadmin;

--
-- Name: gp_resq_priority_backend; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resq_priority_backend AS
 SELECT l.session_id AS rqpsession,
    l.command_count AS rqpcommand,
    l.priority AS rqppriority,
    l.weight AS rqpweight
   FROM gp_list_backend_priorities() l(session_id integer, command_count integer, priority text, weight integer);


ALTER TABLE gp_toolkit.gp_resq_priority_backend OWNER TO gpadmin;

--
-- Name: gp_resq_priority_statement; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resq_priority_statement AS
 SELECT psa.datname AS rqpdatname,
    psa.usename AS rqpusename,
    rpb.rqpsession,
    rpb.rqpcommand,
    rpb.rqppriority,
    rpb.rqpweight,
    psa.query AS rqpquery
   FROM (gp_toolkit.gp_resq_priority_backend rpb
     JOIN pg_stat_activity psa ON ((rpb.rqpsession = psa.sess_id)))
  WHERE (psa.query <> '<IDLE>'::text);


ALTER TABLE gp_toolkit.gp_resq_priority_statement OWNER TO gpadmin;

--
-- Name: gp_resq_role; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resq_role AS
 SELECT pgr.rolname AS rrrolname,
    pgrq.rsqname AS rrrsqname
   FROM (pg_roles pgr
     LEFT JOIN pg_resqueue pgrq ON ((pgr.rolresqueue = pgrq.oid)));


ALTER TABLE gp_toolkit.gp_resq_role OWNER TO gpadmin;

--
-- Name: gp_resqueue_status; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_resqueue_status AS
 SELECT q.oid AS queueid,
    q.rsqname,
    (t1.value)::integer AS rsqcountlimit,
    (t2.value)::integer AS rsqcountvalue,
    (t3.value)::real AS rsqcostlimit,
    (t4.value)::real AS rsqcostvalue,
    (t5.value)::real AS rsqmemorylimit,
    (t6.value)::real AS rsqmemoryvalue,
    (t7.value)::integer AS rsqwaiters,
    (t8.value)::integer AS rsqholders
   FROM pg_resqueue q,
    pg_resqueue_status_kv() t1(queueid oid, key text, value text),
    pg_resqueue_status_kv() t2(queueid oid, key text, value text),
    pg_resqueue_status_kv() t3(queueid oid, key text, value text),
    pg_resqueue_status_kv() t4(queueid oid, key text, value text),
    pg_resqueue_status_kv() t5(queueid oid, key text, value text),
    pg_resqueue_status_kv() t6(queueid oid, key text, value text),
    pg_resqueue_status_kv() t7(queueid oid, key text, value text),
    pg_resqueue_status_kv() t8(queueid oid, key text, value text)
  WHERE ((((((((((((((((q.oid = t1.queueid) AND (t1.queueid = t2.queueid)) AND (t2.queueid = t3.queueid)) AND (t3.queueid = t4.queueid)) AND (t4.queueid = t5.queueid)) AND (t5.queueid = t6.queueid)) AND (t6.queueid = t7.queueid)) AND (t7.queueid = t8.queueid)) AND (t1.key = 'rsqcountlimit'::text)) AND (t2.key = 'rsqcountvalue'::text)) AND (t3.key = 'rsqcostlimit'::text)) AND (t4.key = 'rsqcostvalue'::text)) AND (t5.key = 'rsqmemorylimit'::text)) AND (t6.key = 'rsqmemoryvalue'::text)) AND (t7.key = 'rsqwaiters'::text)) AND (t8.key = 'rsqholders'::text));


ALTER TABLE gp_toolkit.gp_resqueue_status OWNER TO gpadmin;

--
-- Name: gp_roles_assigned; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_roles_assigned AS
 SELECT pgr.oid AS raroleid,
    pgr.rolname AS rarolename,
    pgam.member AS ramemberid,
    pgr2.rolname AS ramembername
   FROM ((pg_roles pgr
     LEFT JOIN pg_auth_members pgam ON ((pgr.oid = pgam.roleid)))
     LEFT JOIN pg_roles pgr2 ON ((pgam.member = pgr2.oid)));


ALTER TABLE gp_toolkit.gp_roles_assigned OWNER TO gpadmin;

--
-- Name: gp_table_indexes; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_table_indexes AS
 SELECT ti.tireloid,
    ti.tiidxoid,
    fntbl.fnnspname AS titableschemaname,
    fntbl.fnrelname AS titablename,
    fnidx.fnnspname AS tiindexschemaname,
    fnidx.fnrelname AS tiindexname
   FROM ((( SELECT pgc.oid AS tireloid,
            pgc2.oid AS tiidxoid
           FROM (((pg_class pgc
             JOIN pg_index pgi ON ((pgc.oid = pgi.indrelid)))
             JOIN pg_class pgc2 ON ((pgi.indexrelid = pgc2.oid)))
             JOIN gp_toolkit.__gp_user_data_tables_readable udt ON ((udt.autoid = pgc.oid)))) ti
     JOIN gp_toolkit.__gp_fullname fntbl ON ((ti.tireloid = fntbl.fnoid)))
     JOIN gp_toolkit.__gp_fullname fnidx ON ((ti.tiidxoid = fnidx.fnoid)));


ALTER TABLE gp_toolkit.gp_table_indexes OWNER TO gpadmin;

--
-- Name: gp_size_of_all_table_indexes; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_all_table_indexes AS
 SELECT soati.soatioid,
    soati.soatisize,
    fn.fnnspname AS soatischemaname,
    fn.fnrelname AS soatitablename
   FROM (( SELECT ti.tireloid AS soatioid,
            sum(pg_relation_size((ti.tiidxoid)::regclass)) AS soatisize
           FROM gp_toolkit.gp_table_indexes ti
          GROUP BY ti.tireloid) soati
     JOIN gp_toolkit.__gp_fullname fn ON ((soati.soatioid = fn.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_all_table_indexes OWNER TO gpadmin;

--
-- Name: gp_size_of_database; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_database AS
 SELECT pg_database.datname AS sodddatname,
    pg_database_size(pg_database.oid) AS sodddatsize
   FROM pg_database
  WHERE (((pg_database.datname <> 'template0'::name) AND (pg_database.datname <> 'template1'::name)) AND (pg_database.datname <> 'postgres'::name));


ALTER TABLE gp_toolkit.gp_size_of_database OWNER TO gpadmin;

--
-- Name: gp_size_of_index; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_index AS
 SELECT soi.soioid,
    soi.soitableoid,
    soi.soisize,
    fnidx.fnnspname AS soiindexschemaname,
    fnidx.fnrelname AS soiindexname,
    fntbl.fnnspname AS soitableschemaname,
    fntbl.fnrelname AS soitablename
   FROM ((( SELECT pgi.indexrelid AS soioid,
            pgi.indrelid AS soitableoid,
            pg_relation_size((pgi.indexrelid)::regclass) AS soisize
           FROM (pg_index pgi
             JOIN gp_toolkit.__gp_user_data_tables_readable ut ON ((pgi.indrelid = ut.autoid)))) soi
     JOIN gp_toolkit.__gp_fullname fnidx ON ((soi.soioid = fnidx.fnoid)))
     JOIN gp_toolkit.__gp_fullname fntbl ON ((soi.soitableoid = fntbl.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_index OWNER TO gpadmin;

--
-- Name: gp_size_of_table_disk; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_table_disk AS
 SELECT sotd.sotdoid,
    sotd.sotdsize,
    sotd.sotdtoastsize,
    sotd.sotdadditionalsize,
    fn.fnnspname AS sotdschemaname,
    fn.fnrelname AS sotdtablename
   FROM (( SELECT udtr.autoid AS sotdoid,
            pg_relation_size((udtr.autoid)::regclass) AS sotdsize,
                CASE
                    WHEN (udtr.auttoastoid > (0)::oid) THEN pg_total_relation_size((udtr.auttoastoid)::regclass)
                    ELSE (0)::bigint
                END AS sotdtoastsize,
            ((
                CASE
                    WHEN ((ao.segrelid IS NOT NULL) AND (ao.segrelid > (0)::oid)) THEN pg_total_relation_size((ao.segrelid)::regclass)
                    ELSE (0)::bigint
                END +
                CASE
                    WHEN ((ao.blkdirrelid IS NOT NULL) AND (ao.blkdirrelid > (0)::oid)) THEN pg_total_relation_size((ao.blkdirrelid)::regclass)
                    ELSE (0)::bigint
                END) +
                CASE
                    WHEN ((ao.visimaprelid IS NOT NULL) AND (ao.visimaprelid > (0)::oid)) THEN pg_total_relation_size((ao.visimaprelid)::regclass)
                    ELSE (0)::bigint
                END) AS sotdadditionalsize
           FROM (( SELECT __gp_user_data_tables_readable.autnspname,
                    __gp_user_data_tables_readable.autrelname,
                    __gp_user_data_tables_readable.autrelkind,
                    __gp_user_data_tables_readable.autreltuples,
                    __gp_user_data_tables_readable.autrelpages,
                    __gp_user_data_tables_readable.autrelacl,
                    __gp_user_data_tables_readable.autoid,
                    __gp_user_data_tables_readable.auttoastoid,
                    __gp_user_data_tables_readable.autrelstorage
                   FROM gp_toolkit.__gp_user_data_tables_readable
                  WHERE (__gp_user_data_tables_readable.autrelstorage <> 'x'::"char")) udtr
             LEFT JOIN pg_appendonly ao ON ((udtr.autoid = ao.relid)))) sotd
     JOIN gp_toolkit.__gp_fullname fn ON ((sotd.sotdoid = fn.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_table_disk OWNER TO gpadmin;

--
-- Name: gp_size_of_partition_and_indexes_disk; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_partition_and_indexes_disk AS
 SELECT sopaid.sopaidparentoid,
    sopaid.sopaidpartitionoid,
    sopaid.sopaidpartitiontablesize,
    sopaid.sopaidpartitionindexessize,
    fnparent.fnnspname AS sopaidparentschemaname,
    fnparent.fnrelname AS sopaidparenttablename,
    fnpart.fnnspname AS sopaidpartitionschemaname,
    fnpart.fnrelname AS sopaidpartitiontablename
   FROM ((( SELECT pgp.parrelid AS sopaidparentoid,
            pgpr.parchildrelid AS sopaidpartitionoid,
            ((sotd.sotdsize + sotd.sotdtoastsize) + sotd.sotdadditionalsize) AS sopaidpartitiontablesize,
            COALESCE(soati.soatisize, (0)::numeric) AS sopaidpartitionindexessize
           FROM (((pg_partition pgp
             JOIN pg_partition_rule pgpr ON ((pgp.oid = pgpr.paroid)))
             JOIN gp_toolkit.gp_size_of_table_disk sotd ON ((sotd.sotdoid = pgpr.parchildrelid)))
             LEFT JOIN gp_toolkit.gp_size_of_all_table_indexes soati ON ((soati.soatioid = pgpr.parchildrelid)))) sopaid
     JOIN gp_toolkit.__gp_fullname fnparent ON ((sopaid.sopaidparentoid = fnparent.fnoid)))
     JOIN gp_toolkit.__gp_fullname fnpart ON ((sopaid.sopaidpartitionoid = fnpart.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_partition_and_indexes_disk OWNER TO gpadmin;

--
-- Name: gp_size_of_table_and_indexes_disk; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_table_and_indexes_disk AS
 SELECT sotaid.sotaidoid,
    sotaid.sotaidtablesize,
    sotaid.sotaididxsize,
    fn.fnnspname AS sotaidschemaname,
    fn.fnrelname AS sotaidtablename
   FROM (( SELECT sotd.sotdoid AS sotaidoid,
            ((sotd.sotdsize + sotd.sotdtoastsize) + sotd.sotdadditionalsize) AS sotaidtablesize,
                CASE
                    WHEN (soati.soatisize IS NULL) THEN (0)::numeric
                    ELSE soati.soatisize
                END AS sotaididxsize
           FROM (gp_toolkit.gp_size_of_table_disk sotd
             LEFT JOIN gp_toolkit.gp_size_of_all_table_indexes soati ON ((sotd.sotdoid = soati.soatioid)))) sotaid
     JOIN gp_toolkit.__gp_fullname fn ON ((sotaid.sotaidoid = fn.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_table_and_indexes_disk OWNER TO gpadmin;

--
-- Name: gp_size_of_schema_disk; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_schema_disk AS
 SELECT un.aunnspname AS sosdnsp,
    COALESCE(sum(sotaid.sotaidtablesize), (0)::numeric) AS sosdschematablesize,
    COALESCE(sum(sotaid.sotaididxsize), (0)::numeric) AS sosdschemaidxsize
   FROM ((gp_toolkit.gp_size_of_table_and_indexes_disk sotaid
     JOIN gp_toolkit.__gp_fullname fn ON ((sotaid.sotaidoid = fn.fnoid)))
     RIGHT JOIN gp_toolkit.__gp_user_namespaces un ON ((un.aunnspname = fn.fnnspname)))
  GROUP BY un.aunnspname;


ALTER TABLE gp_toolkit.gp_size_of_schema_disk OWNER TO gpadmin;

--
-- Name: gp_size_of_table_uncompressed; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_table_uncompressed AS
 SELECT sotu.sotuoid,
    sotu.sotusize,
    fn.fnnspname AS sotuschemaname,
    fn.fnrelname AS sotutablename
   FROM (( SELECT sotd.sotdoid AS sotuoid,
            ((
                CASE
                    WHEN iao.iaotype THEN
                    CASE
                        WHEN (pg_relation_size((sotd.sotdoid)::regclass) = 0) THEN (0)::double precision
                        ELSE ((pg_relation_size((sotd.sotdoid)::regclass))::double precision *
                        CASE
                            WHEN (get_ao_compression_ratio((sotd.sotdoid)::regclass) = ((-1))::double precision) THEN NULL::double precision
                            ELSE get_ao_compression_ratio((sotd.sotdoid)::regclass)
                        END)
                    END
                    ELSE (sotd.sotdsize)::double precision
                END + (sotd.sotdtoastsize)::double precision) + (sotd.sotdadditionalsize)::double precision) AS sotusize
           FROM (gp_toolkit.gp_size_of_table_disk sotd
             JOIN gp_toolkit.__gp_is_append_only iao ON ((sotd.sotdoid = iao.iaooid)))) sotu
     JOIN gp_toolkit.__gp_fullname fn ON ((sotu.sotuoid = fn.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_table_uncompressed OWNER TO gpadmin;

--
-- Name: gp_size_of_table_and_indexes_licensing; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_size_of_table_and_indexes_licensing AS
 SELECT sotail.sotailoid,
    sotail.sotailtablesizedisk,
    sotail.sotailtablesizeuncompressed,
    sotail.sotailindexessize,
    fn.fnnspname AS sotailschemaname,
    fn.fnrelname AS sotailtablename
   FROM (( SELECT sotu.sotuoid AS sotailoid,
            sotaid.sotaidtablesize AS sotailtablesizedisk,
            sotu.sotusize AS sotailtablesizeuncompressed,
            sotaid.sotaididxsize AS sotailindexessize
           FROM (gp_toolkit.gp_size_of_table_uncompressed sotu
             JOIN gp_toolkit.gp_size_of_table_and_indexes_disk sotaid ON ((sotu.sotuoid = sotaid.sotaidoid)))) sotail
     JOIN gp_toolkit.__gp_fullname fn ON ((sotail.sotailoid = fn.fnoid)));


ALTER TABLE gp_toolkit.gp_size_of_table_and_indexes_licensing OWNER TO gpadmin;

--
-- Name: gp_skew_coefficients; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_skew_coefficients AS
 SELECT skew.skewoid AS skcoid,
    pgn.nspname AS skcnamespace,
    pgc.relname AS skcrelname,
    skew.skewval AS skccoeff
   FROM ((gp_toolkit.__gp_skew_coefficients() skew(skewoid, skewval)
     JOIN pg_class pgc ON ((skew.skewoid = pgc.oid)))
     JOIN pg_namespace pgn ON ((pgc.relnamespace = pgn.oid)));


ALTER TABLE gp_toolkit.gp_skew_coefficients OWNER TO gpadmin;

--
-- Name: gp_skew_idle_fractions; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_skew_idle_fractions AS
 SELECT skew.skewoid AS sifoid,
    pgn.nspname AS sifnamespace,
    pgc.relname AS sifrelname,
    skew.skewval AS siffraction
   FROM ((gp_toolkit.__gp_skew_idle_fractions() skew(skewoid, skewval)
     JOIN pg_class pgc ON ((skew.skewoid = pgc.oid)))
     JOIN pg_namespace pgn ON ((pgc.relnamespace = pgn.oid)));


ALTER TABLE gp_toolkit.gp_skew_idle_fractions OWNER TO gpadmin;

--
-- Name: gp_stats_missing; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_stats_missing AS
 SELECT aut.autnspname AS smischema,
    aut.autrelname AS smitable,
        CASE
            WHEN ((aut.autrelpages = 0) OR (aut.autreltuples = (0)::double precision)) THEN false
            ELSE true
        END AS smisize,
    attrs.attcnt AS smicols,
    COALESCE(bar.stacnt, (0)::bigint) AS smirecs
   FROM ((gp_toolkit.__gp_user_tables aut
     JOIN ( SELECT pg_attribute.attrelid,
            count(*) AS attcnt
           FROM pg_attribute
          WHERE ((pg_attribute.attnum > 0) AND (pg_attribute.attisdropped = false))
          GROUP BY pg_attribute.attrelid) attrs ON ((aut.autoid = attrs.attrelid)))
     LEFT JOIN ( SELECT pg_statistic.starelid,
            count(*) AS stacnt
           FROM pg_statistic
          GROUP BY pg_statistic.starelid) bar ON ((aut.autoid = bar.starelid)))
  WHERE (((aut.autrelkind = 'r'::"char") AND ((aut.autrelpages = 0) OR (aut.autreltuples = (0)::double precision))) OR ((bar.stacnt IS NOT NULL) AND (attrs.attcnt > bar.stacnt)));


ALTER TABLE gp_toolkit.gp_stats_missing OWNER TO gpadmin;

--
-- Name: gp_workfile_entries; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_workfile_entries AS
 WITH all_entries AS (
         SELECT c_1.segid,
            c_1.prefix,
            c_1.size,
            c_1.optype,
            c_1.slice,
            c_1.sessionid,
            c_1.commandid,
            c_1.numfiles
           FROM gp_toolkit.__gp_workfile_entries_f_on_master() c_1(segid integer, prefix text, size bigint, optype text, slice integer, sessionid integer, commandid integer, numfiles integer)
        UNION ALL
         SELECT c_1.segid,
            c_1.prefix,
            c_1.size,
            c_1.optype,
            c_1.slice,
            c_1.sessionid,
            c_1.commandid,
            c_1.numfiles
           FROM gp_toolkit.__gp_workfile_entries_f_on_segments() c_1(segid integer, prefix text, size bigint, optype text, slice integer, sessionid integer, commandid integer, numfiles integer)
        )
 SELECT s.datname,
    s.pid,
    c.sessionid AS sess_id,
    c.commandid AS command_cnt,
    s.usename,
    s.query,
    c.segid,
    c.slice,
    c.optype,
    c.size,
    c.numfiles,
    c.prefix
   FROM (all_entries c
     LEFT JOIN pg_stat_activity s ON ((c.sessionid = s.sess_id)));


ALTER TABLE gp_toolkit.gp_workfile_entries OWNER TO gpadmin;

--
-- Name: gp_workfile_mgr_used_diskspace; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_workfile_mgr_used_diskspace AS
 SELECT c.segid,
    c.bytes
   FROM gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() c(segid integer, bytes bigint)
UNION ALL
 SELECT c.segid,
    c.bytes
   FROM gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() c(segid integer, bytes bigint)
  ORDER BY 1;


ALTER TABLE gp_toolkit.gp_workfile_mgr_used_diskspace OWNER TO gpadmin;

--
-- Name: gp_workfile_usage_per_query; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_workfile_usage_per_query AS
 SELECT gp_workfile_entries.datname,
    gp_workfile_entries.pid,
    gp_workfile_entries.sess_id,
    gp_workfile_entries.command_cnt,
    gp_workfile_entries.usename,
    gp_workfile_entries.query,
    gp_workfile_entries.segid,
    sum(gp_workfile_entries.size) AS size,
    sum(gp_workfile_entries.numfiles) AS numfiles
   FROM gp_toolkit.gp_workfile_entries
  GROUP BY gp_workfile_entries.datname, gp_workfile_entries.pid, gp_workfile_entries.sess_id, gp_workfile_entries.command_cnt, gp_workfile_entries.usename, gp_workfile_entries.query, gp_workfile_entries.segid;


ALTER TABLE gp_toolkit.gp_workfile_usage_per_query OWNER TO gpadmin;

--
-- Name: gp_workfile_usage_per_segment; Type: VIEW; Schema: gp_toolkit; Owner: gpadmin
--

CREATE VIEW gp_toolkit.gp_workfile_usage_per_segment AS
 SELECT gpseg.content AS segid,
    COALESCE(sum(wfe.size), (0)::numeric) AS size,
    sum(wfe.numfiles) AS numfiles
   FROM (( SELECT gp_segment_configuration.content
           FROM gp_segment_configuration
          WHERE (gp_segment_configuration.role = 'p'::"char")) gpseg
     LEFT JOIN gp_toolkit.gp_workfile_entries wfe ON ((gpseg.content = wfe.segid)))
  GROUP BY gpseg.content;


ALTER TABLE gp_toolkit.gp_workfile_usage_per_segment OWNER TO gpadmin;

--
-- Name: tab10; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab10 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab10 OWNER TO gpadmin;

--
-- Name: tab11; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab11 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab11 OWNER TO gpadmin;

--
-- Name: tab12; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab12 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab12 OWNER TO gpadmin;

--
-- Name: tab13; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab13 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab13 OWNER TO gpadmin;

--
-- Name: tab14; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab14 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab14 OWNER TO gpadmin;

--
-- Name: tab15; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab15 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab15 OWNER TO gpadmin;

--
-- Name: tab16; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab16 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab16 OWNER TO gpadmin;

--
-- Name: tab17; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab17 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab17 OWNER TO gpadmin;

--
-- Name: tab18; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab18 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab18 OWNER TO gpadmin;

--
-- Name: tab19; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab19 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab19 OWNER TO gpadmin;

--
-- Name: tab2; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab2 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab2 OWNER TO gpadmin;

--
-- Name: tab20; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab20 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab20 OWNER TO gpadmin;

--
-- Name: tab3; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab3 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab3 OWNER TO gpadmin;

--
-- Name: tab4; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab4 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab4 OWNER TO gpadmin;

--
-- Name: tab5; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab5 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab5 OWNER TO gpadmin;

--
-- Name: tab6; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab6 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab6 OWNER TO gpadmin;

--
-- Name: tab7; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab7 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab7 OWNER TO gpadmin;

--
-- Name: tab8; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab8 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab8 OWNER TO gpadmin;

--
-- Name: tab9; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.tab9 (
    generate_series integer
)
 DISTRIBUTED RANDOMLY;


ALTER TABLE public.tab9 OWNER TO gpadmin;

--
-- Name: SCHEMA gp_toolkit; Type: ACL; Schema: -; Owner: gpadmin
--

REVOKE ALL ON SCHEMA gp_toolkit FROM PUBLIC;
REVOKE ALL ON SCHEMA gp_toolkit FROM gpadmin;
GRANT ALL ON SCHEMA gp_toolkit TO gpadmin;
GRANT USAGE ON SCHEMA gp_toolkit TO PUBLIC;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: gpadmin
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM gpadmin;
GRANT ALL ON SCHEMA public TO gpadmin;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: FUNCTION __gp_aocsseg(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aocsseg(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aocsseg(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aocsseg(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aocsseg(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aocsseg_history(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aocsseg_history(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aoseg(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aoseg(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aoseg(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aoseg(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aoseg(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aoseg_history(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aoseg_history(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aoseg_history(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aoseg_history(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aoseg_history(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aovisimap(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aovisimap_entry(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap_entry(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_aovisimap_hidden_info(regclass); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_aovisimap_hidden_info(regclass) TO PUBLIC;


--
-- Name: FUNCTION __gp_param_setting_on_master(character varying); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_master(character varying) TO PUBLIC;


--
-- Name: FUNCTION __gp_param_setting_on_segments(character varying); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_param_setting_on_segments(character varying) TO PUBLIC;


--
-- Name: FUNCTION __gp_skew_coefficients(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_skew_coefficients() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_skew_coefficients() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_skew_coefficients() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_skew_coefficients() TO PUBLIC;


--
-- Name: FUNCTION __gp_skew_idle_fractions(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_skew_idle_fractions() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_skew_idle_fractions() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_skew_idle_fractions() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_skew_idle_fractions() TO PUBLIC;


--
-- Name: FUNCTION __gp_workfile_entries_f_on_master(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_master() TO PUBLIC;


--
-- Name: FUNCTION __gp_workfile_entries_f_on_segments(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_entries_f_on_segments() TO PUBLIC;


--
-- Name: FUNCTION __gp_workfile_mgr_used_diskspace_f_on_master(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_master() TO PUBLIC;


--
-- Name: FUNCTION __gp_workfile_mgr_used_diskspace_f_on_segments(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.__gp_workfile_mgr_used_diskspace_f_on_segments() TO PUBLIC;


--
-- Name: FUNCTION gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_bloat_diag(btdrelpages integer, btdexppages numeric, aotable boolean, OUT bltidx integer, OUT bltdiag text) TO PUBLIC;


--
-- Name: FUNCTION gp_param_setting(character varying); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_param_setting(character varying) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_param_setting(character varying) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_param_setting(character varying) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_param_setting(character varying) TO PUBLIC;


--
-- Name: FUNCTION gp_param_settings(); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_param_settings() FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_param_settings() FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_param_settings() TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_param_settings() TO PUBLIC;


--
-- Name: FUNCTION gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_coefficient(targetoid oid, OUT skcoid oid, OUT skccoeff numeric) TO PUBLIC;


--
-- Name: FUNCTION gp_skew_details(oid); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_details(oid) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_details(oid) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_details(oid) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_details(oid) TO PUBLIC;


--
-- Name: FUNCTION gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.gp_skew_idle_fraction(targetoid oid, OUT sifoid oid, OUT siffraction numeric) TO PUBLIC;


--
-- Name: FUNCTION pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.pg_resgroup_check_move_query(session_id integer, groupid oid, OUT session_mem integer, OUT available_mem integer) TO PUBLIC;


--
-- Name: FUNCTION pg_resgroup_move_query(session_id integer, groupid text); Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) FROM PUBLIC;
REVOKE ALL ON FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) FROM gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) TO gpadmin;
GRANT ALL ON FUNCTION gp_toolkit.pg_resgroup_move_query(session_id integer, groupid text) TO PUBLIC;


--
-- Name: TABLE __gp_fullname; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_fullname FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_fullname FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_fullname TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_fullname TO PUBLIC;


--
-- Name: TABLE __gp_is_append_only; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_is_append_only FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_is_append_only FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_is_append_only TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_is_append_only TO PUBLIC;


--
-- Name: TABLE __gp_log_master_ext; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_log_master_ext FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_log_master_ext FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_log_master_ext TO gpadmin;


--
-- Name: TABLE __gp_log_segment_ext; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_log_segment_ext FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_log_segment_ext FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_log_segment_ext TO gpadmin;


--
-- Name: TABLE __gp_number_of_segments; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_number_of_segments FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_number_of_segments FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_number_of_segments TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_number_of_segments TO PUBLIC;


--
-- Name: TABLE __gp_user_namespaces; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_user_namespaces FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_user_namespaces FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_user_namespaces TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_user_namespaces TO PUBLIC;


--
-- Name: TABLE __gp_user_tables; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_user_tables FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_user_tables FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_user_tables TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_user_tables TO PUBLIC;


--
-- Name: TABLE __gp_user_data_tables; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_user_data_tables FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_user_data_tables FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_user_data_tables TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_user_data_tables TO PUBLIC;


--
-- Name: TABLE __gp_user_data_tables_readable; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.__gp_user_data_tables_readable FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.__gp_user_data_tables_readable FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.__gp_user_data_tables_readable TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.__gp_user_data_tables_readable TO PUBLIC;


--
-- Name: TABLE gp_bloat_expected_pages; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_bloat_expected_pages FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_bloat_expected_pages FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_bloat_expected_pages TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_bloat_expected_pages TO PUBLIC;


--
-- Name: TABLE gp_bloat_diag; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_bloat_diag FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_bloat_diag FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_bloat_diag TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_bloat_diag TO PUBLIC;


--
-- Name: TABLE gp_locks_on_relation; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_locks_on_relation FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_locks_on_relation FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_locks_on_relation TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_locks_on_relation TO PUBLIC;


--
-- Name: TABLE gp_locks_on_resqueue; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_locks_on_resqueue FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_locks_on_resqueue FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_locks_on_resqueue TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_locks_on_resqueue TO PUBLIC;


--
-- Name: TABLE gp_log_command_timings; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_log_command_timings FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_log_command_timings FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_log_command_timings TO gpadmin;


--
-- Name: TABLE gp_log_system; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_log_system FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_log_system FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_log_system TO gpadmin;


--
-- Name: TABLE gp_log_database; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_log_database FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_log_database FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_log_database TO gpadmin;


--
-- Name: TABLE gp_log_master_concise; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_log_master_concise FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_log_master_concise FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_log_master_concise TO gpadmin;


--
-- Name: TABLE gp_param_settings_seg_value_diffs; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_param_settings_seg_value_diffs FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_param_settings_seg_value_diffs FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_param_settings_seg_value_diffs TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_param_settings_seg_value_diffs TO PUBLIC;


--
-- Name: TABLE gp_pgdatabase_invalid; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_pgdatabase_invalid FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_pgdatabase_invalid FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_pgdatabase_invalid TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_pgdatabase_invalid TO PUBLIC;


--
-- Name: TABLE gp_resgroup_config; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_config FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_config FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resgroup_config TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resgroup_config TO PUBLIC;


--
-- Name: TABLE gp_resgroup_status; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resgroup_status TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resgroup_status TO PUBLIC;


--
-- Name: TABLE gp_resgroup_status_per_host; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status_per_host FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status_per_host FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resgroup_status_per_host TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resgroup_status_per_host TO PUBLIC;


--
-- Name: TABLE gp_resgroup_status_per_segment; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status_per_segment FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resgroup_status_per_segment FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resgroup_status_per_segment TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resgroup_status_per_segment TO PUBLIC;


--
-- Name: TABLE gp_resq_activity; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resq_activity FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resq_activity FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resq_activity TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resq_activity TO PUBLIC;


--
-- Name: TABLE gp_resq_activity_by_queue; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resq_activity_by_queue FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resq_activity_by_queue FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resq_activity_by_queue TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resq_activity_by_queue TO PUBLIC;


--
-- Name: TABLE gp_resq_priority_backend; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resq_priority_backend FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resq_priority_backend FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resq_priority_backend TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resq_priority_backend TO PUBLIC;


--
-- Name: TABLE gp_resq_priority_statement; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resq_priority_statement FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resq_priority_statement FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resq_priority_statement TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resq_priority_statement TO PUBLIC;


--
-- Name: TABLE gp_resq_role; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resq_role FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resq_role FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resq_role TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resq_role TO PUBLIC;


--
-- Name: TABLE gp_resqueue_status; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_resqueue_status FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_resqueue_status FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_resqueue_status TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_resqueue_status TO PUBLIC;


--
-- Name: TABLE gp_roles_assigned; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_roles_assigned FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_roles_assigned FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_roles_assigned TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_roles_assigned TO PUBLIC;


--
-- Name: TABLE gp_table_indexes; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_table_indexes FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_table_indexes FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_table_indexes TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_table_indexes TO PUBLIC;


--
-- Name: TABLE gp_size_of_all_table_indexes; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_all_table_indexes FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_all_table_indexes FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_all_table_indexes TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_all_table_indexes TO PUBLIC;


--
-- Name: TABLE gp_size_of_database; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_database FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_database FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_database TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_database TO PUBLIC;


--
-- Name: TABLE gp_size_of_index; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_index FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_index FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_index TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_index TO PUBLIC;


--
-- Name: TABLE gp_size_of_table_disk; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_disk FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_disk FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_table_disk TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_table_disk TO PUBLIC;


--
-- Name: TABLE gp_size_of_partition_and_indexes_disk; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_partition_and_indexes_disk FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_partition_and_indexes_disk FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_partition_and_indexes_disk TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_partition_and_indexes_disk TO PUBLIC;


--
-- Name: TABLE gp_size_of_table_and_indexes_disk; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_disk FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_disk FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_disk TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_table_and_indexes_disk TO PUBLIC;


--
-- Name: TABLE gp_size_of_schema_disk; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_schema_disk FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_schema_disk FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_schema_disk TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_size_of_schema_disk TO PUBLIC;


--
-- Name: TABLE gp_size_of_table_uncompressed; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_uncompressed FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_uncompressed FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_table_uncompressed TO gpadmin;


--
-- Name: TABLE gp_size_of_table_and_indexes_licensing; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_licensing FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_licensing FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_size_of_table_and_indexes_licensing TO gpadmin;


--
-- Name: TABLE gp_skew_coefficients; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_skew_coefficients FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_skew_coefficients FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_skew_coefficients TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_skew_coefficients TO PUBLIC;


--
-- Name: TABLE gp_skew_idle_fractions; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_skew_idle_fractions FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_skew_idle_fractions FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_skew_idle_fractions TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_skew_idle_fractions TO PUBLIC;


--
-- Name: TABLE gp_stats_missing; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_stats_missing FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_stats_missing FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_stats_missing TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_stats_missing TO PUBLIC;


--
-- Name: TABLE gp_workfile_entries; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_workfile_entries FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_workfile_entries FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_workfile_entries TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_workfile_entries TO PUBLIC;


--
-- Name: TABLE gp_workfile_mgr_used_diskspace; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_workfile_mgr_used_diskspace FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_workfile_mgr_used_diskspace FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_workfile_mgr_used_diskspace TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_workfile_mgr_used_diskspace TO PUBLIC;


--
-- Name: TABLE gp_workfile_usage_per_query; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_workfile_usage_per_query FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_workfile_usage_per_query FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_workfile_usage_per_query TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_workfile_usage_per_query TO PUBLIC;


--
-- Name: TABLE gp_workfile_usage_per_segment; Type: ACL; Schema: gp_toolkit; Owner: gpadmin
--

REVOKE ALL ON TABLE gp_toolkit.gp_workfile_usage_per_segment FROM PUBLIC;
REVOKE ALL ON TABLE gp_toolkit.gp_workfile_usage_per_segment FROM gpadmin;
GRANT ALL ON TABLE gp_toolkit.gp_workfile_usage_per_segment TO gpadmin;
GRANT SELECT ON TABLE gp_toolkit.gp_workfile_usage_per_segment TO PUBLIC;


--
-- Greenplum Database database dump complete
--

