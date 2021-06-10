-- psql:
-- \l
-- \c nameofdb
-- \dt+ --list tables
-- \dn+ --list schemas
-- \d+ thetable.rdt --display schema of a table
-- CREATE ROLE jlu LOGIN PASSWORD 'secure_password';
-- GRANT CONNECT ON DATABASE postgres TO jlu;
-- GRANT USAGE ON SCHEMA public TO jlu;
-- GRANT pg_read_all_stats TO jlu;
-- GRANT pg_monitor TO jlu;
-- GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO jlu;
-- GRANT ALL PRIVILEGES ON TABLE pg_buffercache TO jlu;
-- GRANT USAGE ON SCHEMA public to jlu; 
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO jlu;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO jlu;
-- GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO jlu;
-- ALTER USER jlu WITH SUPERUSER;
-- SELECT 'GRANT SELECT ON '||schemaname||'."'||tablename||'" TO gis;' FROM pg_tables WHERE schemaname in ('pg_buffercache') ORDER BY schemaname, tablename;
-- grant all privileges on database <dbname> to <username> ;

SELECT rolname FROM pg_roles;

-- Number of index scans (per index and per table)
SELECT indexrelname, relname, idx_scan FROM pg_stat_user_indexes;
-- Number of sequential scans (per table)
SELECT relname, seq_scan FROM pg_stat_user_tables;
-- Rows fetched by queries (per database)
SELECT datname, tup_fetched FROM pg_stat_database;
-- Rows returned by queries (per database)
SELECT datname, tup_returned FROM pg_stat_database;
-- Bytes written temporarily to disk to execute queries (per database)*
SELECT datname, temp_bytes FROM pg_stat_database;

-- Rows inserted, updated, deleted by queries (per database)
SELECT datname, tup_inserted, tup_updated, tup_deleted FROM
pg_stat_database;
-- Rows inserted, updated, deleted by queries (per table)
SELECT relname, n_tup_ins, n_tup_upd, n_tup_del FROM pg_stat_user_tables;
-- Heap-only tuple (HOT) updates (per table)
SELECT relname, n_tup_hot_upd FROM pg_stat_user_tables;
-- Total commits and rollbacks across all databases
SELECT SUM(xact_commit) AS total_commits, SUM(xact_rollback)
AS total_rollbacks FROM pg_stat_database;

-- Locks (by table and lock mode)
SELECT mode, pg_class.relname, count(*) FROM pg_locks JOIN pg_class ON
(pg_locks.relation = pg_class.oid) WHERE pg_locks.mode IS NOT NULL AND
pg_class.relname NOT LIKE 'pg_%%' GROUP BY pg_class.relname, mode;
-- deadlocks per db
SELECT datname, deadlocks FROM pg_stat_database;
-- deadrows per table
SELECT relname, n_dead_tup FROM pg_stat_user_tables;

-- Number of active connections
SELECT COUNT(*) FROM pg_stat_activity WHERE state='active';
 -- Percentage of max connections in use
SELECT (SELECT SUM(numbackends) FROM pg_stat_database) / (SELECT
setting::float FROM pg_settings WHERE name = 'max_connections');


-- Number of index scans (per index and per table)
SELECT indexrelname, relname, idx_scan FROM pg_stat_user_indexes ORDER BY idx_scan;
SELECT schemaname || '.' || relname AS table,
  indexrelname AS index,
  pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
  idx_scan as index_scans
FROM pg_stat_user_indexes ui
JOIN pg_index i ON ui.indexrelid = i.indexrelid
WHERE NOT indisunique AND idx_scan < 50 AND pg_relation_size(relid) > 5 * 8192
ORDER BY pg_relation_size(i.indexrelid) / nullif(idx_scan, 0) DESC NULLS FIRST,
pg_relation_size(i.indexrelid) DESC;

-- Disk space used in bytes, excluding indexes (per table)
SELECT relname AS "table_name", pg_size_pretty(pg_table_size(C.oid))
AS "table_size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid
= C.relnamespace) WHERE nspname NOT IN ('pg_catalog',
'information_schema') AND nspname !~ '^pg_toast' AND relkind IN ('r')
ORDER BY pg_table_size(C.oid) DESC;

-- Discover

SELECT schema_name FROM information_schema.schemata;
SELECT nspname FROM pg_catalog.pg_namespace;
SELECT * FROM information_schema.tables;
SELECT * FROM information_schema.tables WHERE table_schema = 'public';
SELECT current_setting('block_size')::int4 AS page_size_bytes; -- 8192
SHOW shared_buffers;
SHOW effective_cache_size;

--- PG BUFFER CACHE
SELECT c.relname, count(*) AS buffers
             FROM pg_buffercache b INNER JOIN pg_class c
             ON b.relfilenode = pg_relation_filenode(c.oid) AND
                b.reldatabase IN (0, (SELECT oid FROM pg_database
                                      WHERE datname = current_database()))
             GROUP BY c.relname
             ORDER BY 2 DESC
             LIMIT 10;

SELECT c.relname
  , pg_size_pretty(count(*) * 8192) as buffered
  , round(100.0 * count(*) / ( SELECT setting FROM pg_settings WHERE name='shared_buffers')::integer,1) AS buffers_percent
  , round(100.0 * count(*) * 8192 / pg_relation_size(c.oid),1) AS percent_of_relation
 FROM pg_class c
 INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
 INNER JOIN pg_database d ON (b.reldatabase = d.oid AND d.datname = current_database())
 WHERE pg_relation_size(c.oid) > 0
 GROUP BY c.oid, c.relname
 ORDER BY 3 DESC
 LIMIT 10;

SELECT pg_size_pretty(count(*) * 8192) 
FROM pg_class c
INNER JOIN pg_buffercache b ON b.relfilenode = c.relfilenode
INNER JOIN pg_database d ON (b.reldatabase = d.oid AND d.datname = current_database())
WHERE c.oid::regclass = 'rdt'::regclass
AND usagecount >= 3;

SELECT pg_size_pretty(count(*) * 8192) as ideal_shared_buffers
FROM pg_buffercache b
WHERE usagecount >= 3;


-- !!!!!!!!!
-- Metsafe
-- !!!!!!!!!
CREATE EXTENSION "adminpack";
CREATE EXTENSION "pg_prewarm";
CREATE EXTENSION "pg_stat_statements";
CREATE EXTENSION "pg_buffercache";
CREATE EXTENSION "postgis";
-- Enable PostGIS (includes raster)
CREATE EXTENSION postgis;
-- Enable Topology
CREATE EXTENSION postgis_topology;
-- Enable PostGIS Advanced 3D 
-- and other geoprocessing algorithms
CREATE EXTENSION postgis_sfcgal;
-- fuzzy matching needed for Tiger
CREATE EXTENSION fuzzystrmatch;
-- rule based standardizer
CREATE EXTENSION address_standardizer;
-- example rule data set
CREATE EXTENSION address_standardizer_data_us;
-- Enable US Tiger Geocoder
CREATE EXTENSION postgis_tiger_geocoder;
-- routing functionality
CREATE EXTENSION pgrouting;
-- spatial foreign data wrappers
CREATE EXTENSION ogr_fdw;
-- LIDAR support
CREATE EXTENSION pointcloud;
-- LIDAR Point cloud patches to geometry type cases
CREATE EXTENSION pointcloud_postgis;

SELECT PostGIS_Full_Version();

CREATE SCHEMA postgis;
CREATE EXTENSION postgis WITH SCHEMA postgis ;
ALTER DATABASE postgres SET search_path TO public, postgis, thetable;

SELECT * FROM information_schema.tables WHERE table_schema = 'thetable';

-- duration is in ms
SET log_min_duration_statement to 10000;
SET debug_print_plan to ON;

SELECT * FROM pg_indexes WHERE tablename = 'rdt';
DROP INDEX "rdt_geom_gist";
DROP INDEX "rdt_idx_composite01";
-- CREATE INDEX rdt_idx_area ON "thetable"."rdt" ("area");
CREATE INDEX rdt_idx_geom ON "thetable"."rdt" USING gist ("geom");
CREATE INDEX rdt_idx_composite01 ON "thetable"."rdt" USING btree ("area","geom","lastrevision"); -- SQL error index row size 7192 exceeds maximum 2172 for index
SET enable_seqscan = OFF;
SET enable_indexscan = OFF;
SET enable_bitmapscan = OFF;
-- SET effective_cache_size TO '1 GB';

ALTER TABLE "thetable"."rdt" ALTER COLUMN "id_trajectory" SET NOT NULL;
ALTER TABLE "thetable"."rdt" ALTER COLUMN "id_cell" SET NOT NULL;
ALTER TABLE "thetable"."rdt" ALTER COLUMN "lastrevision" SET NOT NULL;
ALTER TABLE "thetable"."rdt" ALTER COLUMN "obsorfcsttime" SET NOT NULL;
ALTER TABLE "thetable"."rdt" ALTER COLUMN "geom" SET NOT NULL;
-- ALTER TABLE "thetable"."rdt" ALTER COLUMN "lastrevision" TYPE TIMESTAMP WITH TIME ZONE USING "lastrevision" AT TIME ZONE 'UTC';
-- ALTER TABLE "thetable"."rdt" ALTER COLUMN "obsorfcsttime" TYPE TIMESTAMP WITH TIME ZONE USING "obsorfcsttime" AT TIME ZONE 'UTC';
-- ALTER TABLE "thetable"."rdt" ALTER COLUMN "endvalidity" TYPE TIMESTAMP WITH TIME ZONE USING "endvalidity" AT TIME ZONE 'UTC';

-- add composite primary key to existing table
ALTER TABLE "thetable"."rdt" ADD CONSTRAINT rdt_pkey PRIMARY KEY (obsorfcsttime, lastrevision, id_trajectory, id_cell);

SELECT * FROM "thetable"."rdt" WHERE ST_IsEmpty(geom); --no rows
SELECT * FROM "thetable"."rdt" WHERE NOT geom <> ''
SELECT * FROM "thetable"."rdt" WHERE NOT ST_IsValid(geom); 
SELECT ctid, geom, st_isvalid(geom) FROM "thetable"."rdt" WHERE NOT ST_IsValid(geom);

-- SELECT * FROM "thetable"."rdt" WHERE ST_GeometryType(geom) <> 'ST_Polygon';

-- correct invalid geometry in 3 steps
UPDATE "thetable"."rdt" SET geom = ST_MakeValid(geom) WHERE NOT ST_IsValid(geom);
UPDATE "thetable"."rdt" SET geom = ST_Multi(ST_Simplify(ST_Multi(ST_CollectionExtract(ST_ForceCollection(ST_MakeValid(geom)),3)),0)) WHERE ST_GeometryType(the_geom) = ‘ST_GeometryCollection’;
UPDATE "thetable"."rdt" SET geom = ST_Multi(ST_Simplify(geom,0));
-- correct invalid geometry in 1 step
UPDATE "thetable"."rdt" SET geom = ST_Multi(ST_Buffer(geom,0)) WHERE NOT ST_IsValid(geom);
-- correct invalid geometry in 1 step more loosely
UPDATE "thetable"."rdt" SET geom = ST_Multi(ST_Buffer(geom,0.0000001)) WHERE NOT ST_IsValid(geom);

-- accept only polygon
-- ALTER TABLE "thetable"."rdt" ALTER COLUMN geom TYPE geometry(polygon,4326);
-- accept only multiploygon
-- ALTER TABLE "thetable"."rdt" ALTER COLUMN geom TYPE geometry(multipolygon,4326) USING ST_CollectionExtract(ST_MakeValid(geom),3);
-- accept all geometry type
ALTER TABLE "thetable"."rdt" ALTER COLUMN geom TYPE geometry(Geometry,4326);
ALTER TABLE "thetable"."rdt" ADD CONSTRAINT enforce_valid_geom CHECK (st_isvalid(geom));
ALTER TABLE "thetable"."rdt" ADD CONSTRAINT enforce_geotype_geom CHECK (geometrytype(geom) = ANY (ARRAY['MULTIPOLYGON'::text, 'POLYGON'::text]));
ALTER TABLE "thetable"."rdt" ADD CONSTRAINT enforce_dims_geom CHECK (st_ndims(geom) = 2);

UPDATE "thetable"."rdt" SET the_geom = ST_Force2D("geom");
-- DELETE FROM "thetable"."rdt" WHERE ST_IsValid(geom)=false;

-- CLUSTER "rdt_idx_geom" ON "thetable"."rdt";

SELECT ST_MemSize(ST_GeomFromText('POLYGON ((-66.52 11.26, -66.52 55.5, 7.38 55.5, 7.38 11.26, -66.52 11.26))'));
-------------------
-- For a 50% storage penalty, on a table that has far more large objects than most spatial tables, we achieved a 500% performance improvement. Maybe we shouldn’t apply compression to our large geometry at all?
-- Change the storage type to avoid geom compression
-- TOAST size limit is 2kb
ALTER TABLE "thetable"."rdt" ALTER COLUMN geom SET STORAGE EXTERNAL;
ALTER TABLE "thetable"."rdt" ALTER COLUMN geom SET STORAGE MAIN; -- switch back to default main or extended for geom:Main
-- Force the column to rewrite to update storage of already existing rows
UPDATE "thetable"."rdt" SET geom = ST_Force2D("geom");
----------------------

vacuum analyze "thetable"."rdt";

SET search_path TO 'thetable';
SELECT pg_prewarm('thetable.rdt');
SELECT pg_prewarm('thetable.metar');
SELECT pg_prewarm('thetable.cat');
SELECT pg_prewarm('thetable.lightning');
SELECT pg_prewarm('thetable.aspoc');
SELECT pg_prewarm('thetable.icing');
SELECT pg_prewarm('thetable.sigmet');
SELECT pg_prewarm('thetable.taf');

SELECT MIN(lastrevision) FROM "thetable"."rdt" where "lastrevision" >= '2018-10-01 09:50:00.0'; -- 2018-10-10 04:05:00
SELECT MAX(lastrevision) FROM "thetable"."rdt"; -- 2018-10-15 21:40:00
SELECT * FROM "thetable"."rdt" where "id_cell" = 'OPIC_SAT_20181014143000_01735_afriw';
SELECT * FROM "thetable"."rdt" limit 5;
-- noindex seq scan - cost = 934823.62
-- explain (analyze,buffers)
EXPLAIN SELECT count(*) FROM "thetable"."rdt" WHERE ("geom" && ST_GeomFromText('POLYGON ((-66.52 11.26, -66.52 55.5, 7.38 55.5, 7.38 11.26, -66.52 11.26))', 4326));
-- noindex bitmap index scan - cost = 10776.98
EXPLAIN (ANALYZE,BUFFERS) SELECT * FROM "thetable"."rdt" WHERE ("lastrevision" >= '2018-10-15 05:50:00.0' AND "geom" && ST_GeomFromText('POLYGON ((-66.52 11.26, -66.52 55.5, 7.38 55.5, 7.38 11.26, -66.52 11.26))', 4326) AND "area" != 'EuropeRSS' AND "area" != 'MSGOI' AND "area" != 'GOES-E') ORDER BY "lastrevision" LIMIT 1000000;
-- SELECT * FROM "thetable"."rdt" WHERE ('2018-10-15 09:50:00.0' >= "lastrevision" AND "lastrevision" IS NOT NULL AND "geom" && ST_GeomFromText('POLYGON ((-66.52 11.26, -66.52 55.5, 7.38 55.5, 7.38 11.26, -66.52 11.26))', 4326) AND "area" != 'EuropeRSS' AND "area" IS NOT NULL AND "area" != 'MSGOI' AND "area" != 'GOES-E') limit 10;

EXPLAIN (analyze,buffers) SELECT count(*) FROM "thetable"."rdt" WHERE ("lastrevision" >= '2018-10-14 09:50:00.0' AND "geom" && ST_GeomFromText('POLYGON((-57.64 15.73, 24.09 15.73, 24.09 -43.11, -57.64 -43.11, -57.64 15.73))', 4326) AND "area" != 'EuropeRSS' AND "area" != 'MSGOI' AND "area" != 'GOES-E');

SELECT count(*) FROM "thetable"."rdt" WHERE ("lastrevision" >= '2018-10-15 09:50:00.0' AND "geom" && ST_GeomFromText('POLYGON ((-66.52 11.26, -66.52 55.5, 7.38 55.5, 7.38 11.26, -66.52 11.26))', 4326) AND "area" != 'EuropeRSS' AND "area" != 'MSGOI' AND "area" != 'GOES-E');


-- psql -p 5433 -t -A -d "$THEDATABASE" -c "select format('vacuum full %I.%I;', n.nspname::varchar, t.relname::varchar) FROM pg_class t JOIN pg_namespace n ON n.oid = t.relnamespace WHERE t.relkind = 'r' and n.nspname::varchar = '"$THESCHEMA"' order by 1" | psql -U postgres -p 5433 -d "$THEDATABASE"
