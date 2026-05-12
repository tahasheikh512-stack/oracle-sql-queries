/* TITLE: Regional Manager (RM) Hierarchy Net Sales Report
DESCRIPTION: 
This query calculates the total net and gross sales for a specific RM 
and their entire subordinates' hierarchy using Oracle's CONNECT BY clause.

FEATURES:
- Uses Common Table Expression (CTE) for RM Hierarchy.
- Implements Hierarchical retrieval (START WITH...CONNECT BY).
- Joins hierarchy with sales view (view_rm_net_sale_data).
AUTHOR: Sheikh M Taha
DATE: May 2026
*/

WITH rm_hierarchy AS
 (SELECT ss.si04_id login_id,
         ss.si04_report_to parent_id,
         (SELECT a.si04_first_name || ' ' || a.si04_middle_name || ' ' ||
                 a.si04_last_name
            FROM si04_employee a
           WHERE a.si04_id = ss.si04_report_to) parent_name,
         ss.si04_first_name descrip,
         LEVEL AS lvl,
         ss.crm_status_id
    FROM si04_employee ss
    WHERE ss.crm_status_id NOT IN (9)
   START WITH ss.si04_id = &P_RM_ID
  CONNECT BY PRIOR ss.si04_id = ss.si04_report_to)

SELECT SUM(vw.net_amount) net_sale,
       SUM(vw.gross_sale) gross_sale 
  FROM view_rm_net_sale_data vw
  JOIN rm_hierarchy rh ON rh.login_id = vw.SI04_ID
   where vw.FU05_APPROVAL_DATE BETWEEN '01-jan-2026' AND '12-may-2026'
 ORDER BY rh.lvl;
