/* TITLE: RM Hierarchy AUM Allocation Report
DESCRIPTION: 
This query retrieves Assets Under Management (AUM) data for a specific RM 
and their subordinates. It displays the fund category and amounts allocated 
across the entire organizational hierarchy.

KEY FEATURES:
- Common Table Expression (CTE) for Hierarchy
- Recursive Relationship (CONNECT BY)
- Data Joining with AUM Views
*/

WITH rm_hierarchy AS (
    SELECT ss.si04_id login_id,
           ss.si04_report_to parent_id,
           (SELECT a.si04_first_name || ' ' || a.si04_middle_name || ' ' || a.si04_last_name
            FROM si04_employee a
            WHERE a.si04_id = ss.si04_report_to) parent_name,
           ss.si04_first_name descrip,
           LEVEL AS lvl
    FROM si04_employee ss
    START WITH ss.si04_id = &P_RM_ID
    CONNECT BY PRIOR ss.si04_id = ss.si04_report_to
)
SELECT rh.*, 
       vw.fund_Categ, 
       vw.amount 
FROM view_RM_AUM_DATA vw
JOIN rm_hierarchy rh ON rh.login_id = vw.si04_id;
