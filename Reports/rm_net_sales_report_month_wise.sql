/* PROJECT: RM Net Sales Report
DESCRIPTION: Ye query monthly sales calculate karti hai RM hierarchy ke mutabiq.
AUTHOR: Taha Sheikh
DATE: May 2026
*/

with rm_hierarchy as
 (SELECT ss.si04_id login_id,
         ss.si04_report_to parent_id,
         (select a.si04_first_name || ' ' || a.si04_middle_name || ' ' ||
                 a.si04_last_name
            from si04_employee a
           where a.si04_id = ss.si04_report_to) parent_name,
         ss.si04_first_name descrip,
         LEVEL AS lvl,
         ss.crm_status_id
    FROM si04_employee ss
   where ss.crm_status_id not in (9)
   START WITH ss.si04_id = &P_RM_ID
  CONNECT BY PRIOR ss.si04_id = ss.si04_report_to)

select rh.login_id,
       rh.parent_id,
       rh.parent_name,
       rh.descrip,
       rh.lvl,
       rh.crm_status_id,
       to_char(vw.FU05_APPROVAL_DATE, 'MON-YYYY') mon_dt,
       sum(vw.net_amount) net_sale,
       sum(vw.gross_sale) gross_sale
  from view_rm_net_sale_data vw
  join rm_hierarchy rh
    on rh.login_id = vw.SI04_ID
 where rh.login_id = &P_RM_ID
   and vw.FU05_APPROVAL_DATE between '01-jan-2026' and '12-may-2026'
 group by rh.login_id,
          rh.parent_id,
          rh.parent_name,
          rh.descrip,
          rh.lvl,
          rh.crm_status_id,
          to_char(vw.FU05_APPROVAL_DATE, 'MON-YYYY')
 order by rh.lvl;
