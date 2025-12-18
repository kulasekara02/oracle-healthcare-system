SET ECHO ON
SET PAGESIZE 50
DBMS_OUTPUT.ENABLE(50000);
@oltp_ddl.sql
@oltp_dml.sql
@olap_ddl.sql
@etl_load_plsql.sql
@doc_store_ddl_dml.sql
@kpi_report.sql