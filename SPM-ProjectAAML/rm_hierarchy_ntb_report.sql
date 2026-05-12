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

with rm_hierarchy as
(SELECT ss.si04_id login_id,
         ss.si04_report_to parent_id,
         (select a.si04_first_name || ' ' || a.si04_middle_name || ' ' ||
                 a.si04_last_name
            from si04_employee a
           where a.si04_id = ss.si04_report_to) parent_name,
         ss.si04_first_name descrip,
         LEVEL AS lvl,ss.crm_status_id
    FROM si04_employee ss
    where ss.crm_status_id not in (9)
   START WITH ss.si04_id = &P_RM_ID
  CONNECT BY PRIOR ss.si04_id = ss.si04_report_to)

select rh.*,vw.account_opening_date,vw.NTB from view_RM_NTB_DATA vw
join rm_hierarchy rh
on rh.login_id = vw.si04_employee_id
order by rh.lvl;
