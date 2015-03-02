-- Sanity checks
CREATE CONTINUOUS VIEW cqanalyze0 AS SELECT substring(url::text, 1, 2) FROM stream;
CREATE CONTINUOUS VIEW cqanalyze1 AS SELECT CASE WHEN x::text = '1' THEN 1 END FROM stream;
CREATE CONTINUOUS VIEW cqanalyze2 AS SELECT a::integer FROM stream GROUP BY a;
CREATE CONTINUOUS VIEW cqanalyze3 AS SELECT a::integer FROM stream WHERE a > 10 GROUP BY a;
CREATE CONTINUOUS VIEW cqanalyze4 AS SELECT a::integer, b::integer FROM stream WHERE a > 10 GROUP BY a, b, c HAVING a < 12 AND c::integer > 2;
CREATE CONTINUOUS VIEW cqanalyze5 AS SELECT substring(url::text, 1, 2) AS g, COUNT(*) FROM stream GROUP BY g;
CREATE CONTINUOUS VIEW cqanalyze6 AS SELECT s.id::integer FROM stream s WHERE s.id < 10 AND s.value::integer > 10;

-- Verify that we can infer types for columns appearing outside of the target list
CREATE CONTINUOUS VIEW cqanalyze7 AS SELECT id::integer FROM stream ORDER BY f::integer DESC;
CREATE CONTINUOUS VIEW cqanalyze8 AS SELECT id::integer FROM stream GROUP BY id, url::text;
CREATE CONTINUOUS VIEW cqanalyze9 AS SELECT a::integer, b::integer FROM stream WHERE a > 10 GROUP BY a, b, c HAVING a < 12 AND c::integer > 2;

-- Windows
CREATE CONTINUOUS VIEW cqanalyze10 AS SELECT ts::timestamp, SUM(val::numeric) OVER (ORDER BY ts) FROM stream;
CREATE CONTINUOUS VIEW cqanalyze11 AS SELECT ts::timestamp, AVG(val::numeric) OVER (PARTITION BY ts ORDER BY ts) FROM stream;
CREATE CONTINUOUS VIEW cqanalyze12 AS SELECT ts::timestamp, AVG(val::numeric) OVER (PARTITION BY ts ORDER BY ts) FROM stream;
CREATE CONTINUOUS VIEW cqanalyze13 AS SELECT ts::timestamp, AVG(val::numeric) OVER (PARTITION BY ts ORDER BY ts) FROM stream;

-- Multiple streams
CREATE CONTINUOUS VIEW cqanalyze14 AS SELECT s0.a::integer, s1.b::integer FROM s0, s1;
CREATE CONTINUOUS VIEW cqanalyze15 AS SELECT s0.a::integer, s1.b::integer, s2.c::text FROM s0, s1, s2;

-- Stream-table JOINs
CREATE TABLE t0 (id INTEGER);
CREATE CONTINUOUS VIEW cqanalyze16 AS SELECT s0.id::integer AS s0_id, t0.id AS t0_id FROM s0 JOIN t0 ON s0.id = t0.id;
CREATE CONTINUOUS VIEW cqanalyze17 AS SELECT s.x::integer, t0.id FROM stream s JOIN t0 ON s.x = t0.id;
DROP TABLE t0;

-- Stream-stream JOINs
CREATE CONTINUOUS VIEW cqanalyze18 AS SELECT s0.id::integer as id0, s1.id::integer as id1 FROM s0 JOIN s1 ON s0.id = s1.id;
CREATE CONTINUOUS VIEW cqanalyze19 AS SELECT s0.id::integer AS id0, s1.id::integer AS id1 FROM stream s0 JOIN another_stream s1 ON s0.id = s1.id WHERE s0.id > 10 ORDER BY s1.id DESC;

-- Stream-table-stream JOINs
CREATE table sts (id INTEGER);
CREATE CONTINUOUS VIEW cqanalyze20 AS SELECT s0.id::integer AS id0, s1.x::integer, sts.id AS id1 FROM s0 JOIN sts ON s0.id = sts.id JOIN s1 ON sts.id = s1.x;
CREATE CONTINUOUS VIEW cqanalyze21 AS SELECT s0.id::integer AS id0, s1.x::integer, sts.id AS id1 FROM stream s0 JOIN sts ON s0.id = sts.id JOIN s1 ON sts.id = s1.id::integer WHERE sts.id > 42;
CREATE CONTINUOUS VIEW cqanalyze22 AS SELECT s0.id::integer AS id0, s1.x::integer, sts.id AS id1 FROM stream s0 INNER JOIN sts ON s0.id = sts.id RIGHT OUTER JOIN s1 ON sts.id = s1.id::integer WHERE sts.id > 42;
DROP TABLE sts;

-- Now let's verify our error handling and messages
-- Stream column doesn't have a type
CREATE CONTINUOUS VIEW cqanalyze23 AS SELECT col FROM stream;

-- Column not qualified with a stream
CREATE CONTINUOUS VIEW cqanalyze24 AS SELECT id::integer FROM s0, s1;

-- Column has multiple types
CREATE CONTINUOUS VIEW cqanalyze25 AS SELECT id::integer AS id0, id::text AS id1 FROM stream;

-- Another untyped column with an aliased stream
CREATE CONTINUOUS VIEW cqanalyze26 AS SELECT s.id FROM stream s WHERE s.id < 10;

-- Verify all relevant types are recognized
CREATE CONTINUOUS VIEW cqanalyze27 AS SELECT
a::bigint,
b::bit[2],
c::varbit(5),
d::boolean,
c0::box,
d0::bytea,
e::char(42),
f::varchar(32),
g::cidr,
h::circle,
i::date,
j::float8,
k::inet,
l::integer,
m::json,
n::jsonb,
o::line,
p::lseg,
q::macaddr,
r::money,
s::numeric(1, 1),
t::path,
u::point,
v::polygon,
w::real,
x::smallint,
y::text,
z::time,
aa::timetz,
bb::timestamp,
cc::timestamptz,
dd::tsquery,
ee::tsvector,
ff::uuid,
gg::xml
FROM stream WHERE aa > '2014-01-01 00:00:00' AND n @> '{"key": "value"}'::jsonb AND r > 42.3::money;

-- Verify that type cast for arrival_timestamp is optional
CREATE CONTINUOUS VIEW cqanalyze28 AS SELECT arrival_timestamp FROM test_stream;
CREATE CONTINUOUS VIEW cqanalyze29 AS SELECT key::text, arrival_timestamp FROM test_stream;
CREATE CONTINUOUS VIEW cqanalyze30 AS SELECT key::text FROM test_stream WHERE arrival_timestamp < TIMESTAMP '2004-10-19 10:23:54+02';
CREATE CONTINUOUS VIEW cqanalyze31 AS SELECT key::text, arrival_timestamp::timestamptz FROM test_stream;

-- Verify that we can't do wildcard selections from streams
CREATE CONTINUOUS VIEW cqanalyze32 AS SELECT * from stream;
CREATE CONTINUOUS VIEW cqanalyze33 AS SELECT * from stream, t0;
CREATE CONTINUOUS VIEW cqanalyze34 AS SELECT t0.* from stream, t0;
CREATE CONTINUOUS VIEW cqanalyze35 AS SELECT stream.* from stream, t0;

-- Disallow sorting streams
CREATE CONTINUOUS VIEW cqanalyze36 AS SELECT key::text from stream ORDER BY key;
CREATE CONTINUOUS VIEW cqanalyze37 AS SELECT key::text from stream ORDER BY arrival_time;

-- Sliding window queries
CREATE CONTINUOUS VIEW cqanalyze38 AS SELECT COUNT(*) FROM stream WHERE arrival_timestamp < clock_timestamp() - interval '1 hour';
CREATE CONTINUOUS VIEW cqanalyze39 AS SELECT COUNT(*) FROM stream WHERE arrival_timestamp < clock_timestamp() - interval '1 hour' AND key::text='pipelinedb';
CREATE CONTINUOUS VIEW cqanalyze40 AS SELECT COUNT(*) FROM stream WHERE NOT arrival_timestamp < clock_timestamp() - interval '1 hour';
CREATE CONTINUOUS VIEW cqanalyze41 AS SELECT COUNT(*) FROM stream WHERE arrival_timestamp < clock_timestamp() - interval '1 hour' OR key::text='pipelinedb';
CREATE CONTINUOUS VIEW cqanalyze42 AS SELECT COUNT(*) FROM stream WHERE arrival_timestamp < clock_timestamp() - interval '1 hour' AND arrival_timestamp > clock_timestamp() - interval '5 hour';

-- Hypothetical-set aggregates
CREATE CONTINUOUS VIEW cqanalyze45 AS SELECT g::integer, percent_rank(1 + 3, 2, substring('xxx', 1, 2)) WITHIN GROUP (ORDER BY x::integer, y::integer, z::text) + rank(4, 5, 'x') WITHIN GROUP (ORDER BY x, y, substring(z, 1, 2))  FROM stream GROUP BY g;

CREATE CONTINUOUS VIEW cqanalyze46 AS SELECT rank(0, 1) WITHIN GROUP (ORDER BY x::integer, y::integer) + rank(0) WITHIN GROUP (ORDER BY x) FROM stream;

-- Number of arguments to HS function is inconsistent with the number of GROUP columns
CREATE CONTINUOUS VIEW error_not_created AS SELECT percent_rank(1) WITHIN GROUP (ORDER BY x::integer, y::integer, z::integer) FROM stream;

-- Types of arguments to HS function are inconsistent with GROUP column types
CREATE CONTINUOUS VIEW error_not_created AS SELECT g::integer, dense_rank(2, 3, 4) WITHIN GROUP (ORDER BY x::integer, y::integer, z::text) FROM stream GROUP BY g;

CREATE CONTINUOUS VIEW cqanalyze47 AS SELECT g::integer, rank(2, 3, 4) WITHIN GROUP (ORDER BY x::integer, y::integer, z::integer), sum(x + y + z) FROM stream GROUP BY g;

-- Sliding windows
CREATE CONTINUOUS VIEW cqanalyze48 AS SELECT cume_dist(2) WITHIN GROUP (ORDER BY x::integer DESC) FROM stream WHERE (arrival_timestamp > clock_timestamp() - interval '5 minutes');
CREATE CONTINUOUS VIEW cqanalyze49 AS SELECT percent_rank(2) WITHIN GROUP (ORDER BY x::integer DESC), rank(2) WITHIN GROUP (ORDER BY x) FROM stream WHERE (arrival_timestamp > clock_timestamp() - interval '5 minutes');

-- Verify that we get an error if we try to create a CV that only selects from tables
CREATE TABLE cqanalyze_table (id integer);
CREATE CONTINUOUS VIEW error_not_created AS SELECT cqanalyze_table.id::integer FROM cqanalyze_table;
DROP TABLE cqanalyze_table;

-- Verify that for stream-table joins, the correct error message is generated when the table is missing
CREATE CONTINUOUS VIEW  error_not_created AS SELECT s.id::integer, t.tid FROM stream s JOIN not_a_table t ON s.id = t.tid;
CREATE CONTINUOUS VIEW  error_not_created AS SELECT s.id::integer, tid FROM stream s JOIN not_a_table ON s.id = tid;

-- Ordered-set aggregates
CREATE CONTINUOUS VIEW cqanalyze50 AS SELECT g::integer, percentile_cont(ARRAY[0.2, 0.8]) WITHIN GROUP (ORDER BY x::float), percentile_cont(0.9) WITHIN GROUP (ORDER BY y::integer) + percentile_cont(0.1) WITHIN GROUP (ORDER BY z::numeric) AS col FROM stream GROUP BY g;

CREATE CONTINUOUS VIEW cqanalyze51 AS SELECT g::integer, percentile_cont(0.1) WITHIN GROUP (ORDER BY x::float + y::integer) FROM stream GROUP BY g;

-- Can only sort on a numeric expression
CREATE CONTINUOUS VIEW error_not_created AS SELECT percentile_cont(0.1) WITHIN GROUP (ORDER BY x::text) FROM stream;

-- Sliding windows
CREATE CONTINUOUS VIEW cqanalyze52 AS SELECT g::integer, percentile_cont(ARRAY[0.2, 0.8]) WITHIN GROUP (ORDER BY x::float), percentile_cont(0.9) WITHIN GROUP (ORDER BY y::integer) + percentile_cont(0.1) WITHIN GROUP (ORDER BY z::numeric) AS col FROM stream WHERE (arrival_timestamp > clock_timestamp() - interval '5 minutes') GROUP BY g;

CREATE CONTINUOUS VIEW cqanalyze53 AS SELECT percentile_cont(0.1) WITHIN GROUP (ORDER BY x::float + y::integer) FROM stream WHERE (arrival_timestamp > clock_timestamp() - interval '5 minutes');

DROP CONTINUOUS VIEW cqanalyze0;
DROP CONTINUOUS VIEW cqanalyze1;
DROP CONTINUOUS VIEW cqanalyze2;
DROP CONTINUOUS VIEW cqanalyze3;
DROP CONTINUOUS VIEW cqanalyze4;
DROP CONTINUOUS VIEW cqanalyze5;
DROP CONTINUOUS VIEW cqanalyze6;
DROP CONTINUOUS VIEW cqanalyze7;
DROP CONTINUOUS VIEW cqanalyze8;
DROP CONTINUOUS VIEW cqanalyze9;
DROP CONTINUOUS VIEW cqanalyze10;
DROP CONTINUOUS VIEW cqanalyze11;
DROP CONTINUOUS VIEW cqanalyze12;
DROP CONTINUOUS VIEW cqanalyze13;
DROP CONTINUOUS VIEW cqanalyze14;
DROP CONTINUOUS VIEW cqanalyze15;
DROP CONTINUOUS VIEW cqanalyze16;
DROP CONTINUOUS VIEW cqanalyze17;
DROP CONTINUOUS VIEW cqanalyze18;
DROP CONTINUOUS VIEW cqanalyze19;
DROP CONTINUOUS VIEW cqanalyze20;
DROP CONTINUOUS VIEW cqanalyze21;
DROP CONTINUOUS VIEW cqanalyze22;
DROP CONTINUOUS VIEW cqanalyze23;
DROP CONTINUOUS VIEW cqanalyze24;
DROP CONTINUOUS VIEW cqanalyze25;
DROP CONTINUOUS VIEW cqanalyze26;
DROP CONTINUOUS VIEW cqanalyze27;
DROP CONTINUOUS VIEW cqanalyze28;
DROP CONTINUOUS VIEW cqanalyze29;
DROP CONTINUOUS VIEW cqanalyze30;
DROP CONTINUOUS VIEW cqanalyze31;
DROP CONTINUOUS VIEW cqanalyze32;
DROP CONTINUOUS VIEW cqanalyze33;
DROP CONTINUOUS VIEW cqanalyze34;
DROP CONTINUOUS VIEW cqanalyze35;
DROP CONTINUOUS VIEW cqanalyze36;
DROP CONTINUOUS VIEW cqanalyze37;
DROP CONTINUOUS VIEW cqanalyze38;
DROP CONTINUOUS VIEW cqanalyze39;
DROP CONTINUOUS VIEW cqanalyze40;
DROP CONTINUOUS VIEW cqanalyze41;
DROP CONTINUOUS VIEW cqanalyze42;
DROP CONTINUOUS VIEW cqanalyze45;
DROP CONTINUOUS VIEW cqanalyze46;
DROP CONTINUOUS VIEW cqanalyze47;
DROP CONTINUOUS VIEW cqanalyze48;
DROP CONTINUOUS VIEW cqanalyze49;
DROP CONTINUOUS VIEW cqanalyze50;
DROP CONTINUOUS VIEW cqanalyze51;
DROP CONTINUOUS VIEW cqanalyze52;
DROP CONTINUOUS VIEW cqanalyze53;

-- Regression
CREATE CONTINUOUS VIEW cqregress1 AS SELECT id::integer + avg(id) FROM stream GROUP BY id;
CREATE CONTINUOUS VIEW cqregress2 AS SELECT date_trunc('hour', ts) AS ts FROM stream;
CREATE CONTINUOUS VIEW cqregress3 AS SELECT stream.sid::integer FROM stream;

DROP CONTINUOUS VIEW cqregress1;
DROP CONTINUOUS VIEW cqregress2;
DROP CONTINUOUS VIEW cqregress3;