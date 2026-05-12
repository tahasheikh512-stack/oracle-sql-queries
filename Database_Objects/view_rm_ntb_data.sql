create or replace view view_rm_ntb_data as
select b.si04_employee_id, a.open_date account_opening_date,count(a.portfolio_id) NTB
  from crm_client_portfolios a, crm_client_related_persons b
 where a.crm_client_portfolio_id = b.crm_client_portfolio_id
   and a.crm_status_id = 1 ---- active check
   --and a.open_date between '01-jan-2026' and '06-may-2026'
 group by b.si04_employee_id,a.open_date
;
