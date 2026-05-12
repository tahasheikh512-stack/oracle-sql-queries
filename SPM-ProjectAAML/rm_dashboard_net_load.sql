/* TITLE: RM Dashboard Front-End Net Load Query
DESCRIPTION: 
This query calculates the Net Load (Front-End Load) for a specific RM 
based on the Trade Date and Time. It is designed for dashboard cards 
to track real-time revenue impact.

KEY FEATURES:
- Filters out inactive employees (CRM Status 9).
- Date range filtering for specific period analysis.
- Hierarchical join to ensure data belongs to the correct RM tree.
AUTHOR: Sheikh M Taha
DATE: May 2026
*/

WITH rm_hierarchy AS (
    SELECT ss.si04_id login_id,
           ss.si04_report_to parent_id,
           (SELECT a.si04_first_name || ' ' || a.si04_middle_name || ' ' || a.si04_last_name
            FROM si04_employee a
            WHERE a.si04_id = ss.si04_report_to) parent_name,
           ss.si04_first_name descrip,
           LEVEL AS lvl,
           ss.crm_status_id
    FROM si04_employee ss
    WHERE ss.crm_status_id NOT IN (9)
    START WITH ss.si04_id = &P_RM_ID
    CONNECT BY PRIOR ss.si04_id = ss.si04_report_to
)
SELECT rh.*, 
       vw.TRADE_DATE_TIME, 
       vw.NET_LOAD 
FROM view_RM_NET_LOAD_DATA vw
JOIN rm_hierarchy rh ON rh.login_id = vw.SI04_ID
  where vw.TRADE_DATE_TIME BETWEEN '01-jan-2026' AND '12-may-2026'
ORDER BY rh.lvl;
