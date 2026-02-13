# pgMonitor Extension

## Overview

This extension provides a means to collect metrics within a PostgreSQL database to be used by an external collection source (Prometheus exporter, Icinga/Nagios scraper, etc). Certain metrics are collected, their results stored as materialized views or tables, and refreshed on a per-query configurable timer. This allows the metric scraper to not have to be concerned about the underlying runtime of queries that can be more expensive, especially as the size of the database grows (object size, table statistics, etc). It also allows a functional interface for some metrics to account for differences in underlying system catalogs between PostgreSQL major versions (Ex. new columns in pg_stat_activity, pg_stat_statements).

A background worker is provided to refresh the materialized views and tables automatically without the need for any third-party schedulers.

To see a practical application of this extension using Prometheus/Grafana we welcome you to try out pgMonitor - https://github.com/CrunchyData/pgmonitor

## INSTALLATION

Requirement:

 * PostgreSQL >= 12

### From Source
In the directory where you downloaded pgmonitor, run

    make install

If you do not want the background worker compiled and just want the plain SQL install, you can run this instead:

    make NO_BGW=1 install

Note that without the BGW, refreshing of the materialized views and tables will require manual management outside of the pgMonitor extension.


## CONFIGURATION

### PostgreSQL Setup

The background worker must be loaded on database start by adding the library to shared_preload_libraries in postgresql.conf

    shared_preload_libraries = 'pgmonitor_bgw'     # (change requires restart)

You can also set other control variables for the BGW in postgresql.conf. These can be added/changed at anytime with a simple reload. See the documentation for more details.

`pgmonitor_bgw.dbname` is required at a minimum for maintenance to run on the given database(s). This can be a comma separated list if pgMonitor is installed on more than one database to collect per-database metrics.

    pgmonitor_bgw.dbname = 'proddb'

At this time `pgmonitor_bgw.role` must be a superuser due to elevated privileges that are required to gather all metrics as well as refresh the materialized views. Work is underway to see if this can be run as a non-supuseruser. It currently defaults to `postgres` if not set manually.

    pgmonitor_bgw.role = 'postgres'

The interval defaults to 30 seconds and generally doesn't need to be changed. If you're trying to adjust materialized view or tables refresh timing, see the configuration tables below.

    pgmonitor_bgw.interval = 30

Log into PostgreSQL and run the following commands. Schema is optional (but recommended) and can be whatever you wish, but it cannot be changed after installation. If you're using the BGW, the database cluster can be safely started without having the extension first created in the configured database(s). You can create the extension at any time and the BGW will automatically pick up that it exists without restarting the cluster (as long as shared_preload_libraries was set) and begin running maintenance as configured.


Permissions will have to be granted to the monitoring role to allow it to connect to all user databases that need monitoring and to read and write to all of the extension's objects. Note that by default, all roles have the CONNECT privilege granted.

```sql
CREATE SCHEMA pgm;
CREATE EXTENSION pgmonitor SCHEMA pgm;

CREATE ROLE pgm_monitoring WITH LOGIN;
ALTER ROLE pgm_monitoring SET lock_timeout TO '2min'; -- Monitoring queries should not hold excessive locks
ALTER ROLE pgm_monitoring SET jit TO 'off'; -- Some monitoring queries encounter resource issues when JIT is enabled
```

```sql
SELECT 'GRANT CONNECT ON DATABASE "' || datname || '" TO pgm_monitoring;'
FROM pg_database
WHERE datallowconn = true;
```
This should generate one or more statements similar to the following:

```sql
GRANT CONNECT ON DATABASE "postgres" TO pgm_monitoring;
GRANT CONNECT ON DATABASE "alphadb" TO pgm_monitoring;
```
The following grants allow the necessary access to the pgMonitor extension objects.

```sql
GRANT pg_monitor to pgm_monitoring;
GRANT pg_execute_server_program TO pgm_monitoring;  -- This only necessary for pgbackrest monitoring

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA pgm TO pgm_monitoring;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA pgm TO pgm_monitoring;
GRANT ALL ON ALL TABLES IN SCHEMA pgm TO pgm_monitoring;
```

### Metric configuration

The names of all normal views are stored in `metric_views`. All metrics that are either normal views or have the option to be backed by either a normal view or materialized view are stored here. If a metric is only backed by a materialized view and has no option for a normal view, it will only be stored in `metrics_matviews`.
```
                   Table "pgm.metric_views"
     Column     |  Type   | Collation | Nullable |        Default        
----------------+---------+-----------+----------+-----------------------
 view_schema    | text    |           | not null | 'pgm'::text
 view_name      | text    |           | not null | 
 matview_source | boolean |           | not null | false
 active         | boolean |           | not null | true
 scope          | text    |           | not null | 'global'::text
Indexes:
```

 - `view_schema`
    - Schema containing the view_name
 - `view_name`
    - Name of the view or materialized view in system catalogs
 - `matview_source`
    - Boolean to set whether the metric view is backed by a materialized view. If true, the view must be defined in a way that allows a choice to be made. Example: built in metrics use a function-backed view that checks this flag. Defaults to false. 
 - `active`
    - Boolean that external monitoring tools can use to determine whether this metric is actively used or not
 - `scope`
    - Valid values are "global" or "database"
    - "global" means the values of this metric are the same on every database in the instance (ex. connections, replication, etc)
    - "database" means the values of this metric are only defined on a per database basis (database and table statisics, bloat, etc)
    - Can be used by external scrape tools to be able to determine whether to collect these metrics only once per PostgreSQL instance or once per database inside that instance

Materialized views are stored in the `metric_matviews` configuration table. The background worker uses this table to determine which materialized views are "active" to be refreshed and how often to refresh them.
```
                            Table "pgm.metric_matviews"
       Column       |           Type           | Collation | Nullable |        Default        
--------------------+--------------------------+-----------+----------+-----------------------
 view_schema        | text                     |           | not null | 'pgm'::text
 view_name          | text                     |           | not null | 
 concurrent_refresh | boolean                  |           | not null | true
 run_interval       | interval                 |           | not null | '00:14:00'::interval
 last_run           | timestamp with time zone |           |          | 
 last_run_time      | interval                 |           |          | 
 active             | boolean                  |           | not null | true
 scope              | text                     |           | not null | 'global'::text
```
 - `view_schema`
    - Schema containing the view_name
 - `view_name`
    - Name of the view or materialized view in system catalogs
 - `concurrent_refresh`
    - Boolean to set whether the materalized view can be refreshed concurrently. It is highly recommended that all matviews be written in a manner to support a unique key. Concurrent refreshes avoid any contention while metrics are being scraped by external tools.
 - `run_interval`
    - How often the materalized view should be refreshed. Must be a valid value of the PostgreSQL interval type
 - `last_run`
    - Timestamp of the last time this materalized view was refreshed
 - `last_run_time`
    - How long the last run of this refresh took
 - `active`
    - Boolean to determine whether this materialized view is refreshed as part of automatic maintenance. If false, this matview will not be refreshed automatically. Defaults to true. 
 - `scope`
    - See `metric_views` for the purpose of this column


For metrics that still require storage of results for fast scraping but cannot use a normal or materialized view, it is also possible to use a table and give pgMonitor an SQL statement to run to refresh that table. For example, the included pgBackRest metrics need to use a function that uses a COPY statement.
```
                             Table "pgm.metric_tables"
      Column       |           Type           | Collation | Nullable |        Default  
-------------------+--------------------------+-----------+----------+-----------------------
 table_schema      | text                     |           | not null | 'pgm'::text
 table_name        | text                     |           | not null |
 refresh_statement | text                     |           | not null |
 run_interval      | interval                 |           | not null | '00:10:00'::interval
 last_run          | timestamp with time zone |           |          |
 last_run_time     | interval                 |           |          |
 active            | boolean                  |           | not null | true
 scope             | text                     |           | not null | 'global'::text
```

 - `table_schema`
    - Schema containing the table_name
 - `table_name`
    - Name of the table in system catalogs
 - `refresh_statement`
    - The full SQL statement that is run to refresh the data in `table_name`. Ex: `SELECT pgm.pgbackrest_info()`
 - `active`
    - Boolean to determin whether maintenance will call the refresh_statement as part of regular maintenance. If false, this refresh will not run.
 - See `metric_matviews` for purpose of remaining columns

NORMAL VIEWS:
```
 pgm_archive_command_status
 pgm_backrest_last_diff_backup
 pgm_backrest_last_full_backup
 pgm_backrest_last_incr_backup
 pgm_backrest_last_info
 pgm_backrest_oldest_full_backup
 pgm_connection_stats
 pgm_database_size
 pgm_data_checksum_failure
 pgm_locks
 pgm_pg_is_in_recovery
 pgm_postgresql_version
 pgm_postmaster_runtime
 pgm_postmaster_uptime
 pgm_replication_lag
 pgm_replication_lag_size
 pgm_replication_slots
 pgm_settings_pending_restart
 pgm_stat_bgwriter
 pgm_stat_checkpointer
 pgm_stat_database
 pgm_stat_io_bgwriter
 pgm_stat_user_tables
 pgm_table_size
 pgm_transaction_wraparound
 pgm_wal_activity

```

MAT VIEWS:
```
 pgm_database_size_matview
 pgm_pg_hba_checksum
 pgm_sequence_exhaustion
 pgm_stat_user_tables_matview
 pgm_table_size_matview
```

TABLES:
```
 metric_matviews
 metric_tables
 metric_views
 pgbackrest_info
 pg_hba_checksum
 pg_stat_statements_reset_info
```
FUNCTIONS:
```
 pgm_database_size_view_choice() RETURNS TABLE
 pgm_replication_slots_func() RETURNS TABLE
 pgm_stat_checkpointer_func() RETURNS TABLE
 pgm_stat_io_bgwriter_func() RETURNS TABLE
 pgm_stat_user_tables_func() RETURNS TABLE
 pgm_stat_user_tables_view_choice() RETURNS TABLE
 pgm_table_size_view_choice() RETURNS TABLE
 pgbackrest_info() RETURNS SETOF pgbackrest_info
 pg_hba_checksum_set_valid() RETURNS smallint
 pg_hba_checksum(p_known_hba_hash text DEFAULT NULL)
 pg_stat_statements_func() RETURNS TABLE
 pg_stat_statements_reset_info() RETURNS bigint
 refresh_metrics_legacy (p_object_schema text DEFAULT 'monitor', p_object_name text DEFAULT NULL) RETURNS void
 sequence_exhaustion (p_percent integer DEFAULT 75, OUT count bigint)
 sequence_status() RETURNS TABLE (sequence_name text, last_value bigint, slots numeric, used numeric, percent int, cycle boolean, numleft numeric, table_usage text)
```
PROCEDURE:
```
refresh_metrics (p_object_schema text DEFAULT 'monitor', p_object_name text DEFAULT NULL)
```
