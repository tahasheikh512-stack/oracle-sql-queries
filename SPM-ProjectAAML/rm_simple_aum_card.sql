/* TITLE: Simple AUM Card Query
DESCRIPTION: 
This query is designed for a Dashboard Card or Summary Tile. 
It fetches the AUM (Assets Under Management) amount for a specific RM 
including their entire organizational hierarchy.

KEY FEATURES:
- Lightweight query for Dashboard Cards.
- Uses START WITH...CONNECT BY for RM tree.
- Joins with AUM view to get current amounts.

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
           LEVEL AS lvl
    FROM si04_employee ss
    START WITH ss.si04_id = &P_RM_ID
    CONNECT BY PRIOR ss.si04_id = ss.si04_report_to
)
SELECT rh.*, 
       vw.amount 
FROM view_RM_AUM_DATA vw
JOIN rm_hierarchy rh ON rh.login_id = vw.si04_id;
