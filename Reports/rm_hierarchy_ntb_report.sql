/* TITLE: RM Hierarchy New To Bank (NTB) Report
DESCRIPTION: 
This query fetches NTB (New To Bank) customer data for a specific RM 
and their entire reporting hierarchy. It filters out inactive employees 
(status 9) and joins with the NTB view.

KEY FEATURES:
- Hierarchical Data Processing (CONNECT BY)
- Status Filtering (CRM_STATUS_ID)
- Joins with NTB View (view_RM_NTB_DATA)
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
       vw.NTB 
FROM view_RM_NTB_DATA vw
JOIN rm_hierarchy rh ON rh.login_id = vw.si04_employee_id
ORDER BY rh.lvl;
