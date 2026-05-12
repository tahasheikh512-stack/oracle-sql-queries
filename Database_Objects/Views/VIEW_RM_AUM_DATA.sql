CREATE OR REPLACE VIEW VIEW_RM_AUM_DATA AS
WITH latest_nav AS (
    SELECT /*+ MATERIALIZE */
    fu02_pf06_id, MAX(fu02_date) nav_date
    FROM fu02_nav_info
    WHERE fu02_date <= TRUNC(SYSDATE)
      AND fu02_confirmed = 1
    GROUP BY fu02_pf06_id
),

nav_today AS (
    SELECT /*+ MATERIALIZE */
    f.fu02_pf06_id, f.fu02_avg_nav nav_value
    FROM fu02_nav_info f
    JOIN latest_nav n
      ON f.fu02_pf06_id = n.fu02_pf06_id
     AND f.fu02_date = n.nav_date
),

emp AS (
    SELECT  DISTINCT
           cp.portfolio_id,
           crp.si04_employee_id AS si04_id
    FROM crm_client_portfolios cp
    JOIN crm_client_related_persons crp
      ON cp.crm_client_portfolio_id = crp.crm_client_portfolio_id
   WHERE NVL(crp.is_current, 0) = 1
),

fund_Cat as ( Select /*+ MATERIALIZE */
b.pf06_id,case when ld02.ld02_display_name like '%Equity%' then 'Equity'
 when ld02.ld02_display_name like '%Money Market%' then 'Money Market'
   when ld02.ld02_display_name like '%Income%' then 'Income'
     else 'Others' end fund_Categ
    --  into v_Result
      From Ld01_dimension ld01, ld02_dim_data ld02,pf06_instance b
     Where ld01.ld01_id = ld02.ld02_ld01_id
       and ld01.ld01_no = 291--P_Dim_no
       and ld02.ld02_value = b.pf06_investment_type
       and ld02.Ld02_Status <> -1),

txn AS (
    SELECT /*+ MATERIALIZE */
           fu05.fu05_portfolio_id,
           fu05.fu05_pf06_id,

           SUM(
             (CASE WHEN fu05.fu05_type IN (1,6,7,13,15,17,20,22,24,26,27,29,32,33,34,35,36,39,40,45,51,52,61,62,66,67,74,75,76,77,78,80)
                   THEN 1 ELSE -1 END)
             *
             (CASE
                WHEN (fu05.fu05_type = 1 AND fu05.fu05_allocation_dt IS NULL AND fu05.fu05_modified_date IS NULL)
                THEN 0
                WHEN (fu05.fu05_status <> 1003 AND fu05.fu05_type IN (1,6,7,13,15,17,20,22,24,26,27,29,32,33,34,35,36,39,40,45,51,52,61,62,66,67,74,75,76,77,78,80))
                THEN 0
                ELSE 1
              END)
             *
             (CASE
                WHEN fu05.fu05_status = 1003
                THEN fu05.fu05_application_units
                WHEN NVL(fu05.fu05_application_units, 0) = 0
                THEN fu05.fu05_value_amount / fu05.fu05_confirmed_nav
                ELSE fu05.fu05_application_units
              END)
           ) holdings

    FROM fu05_transaction fu05

-----excluding reversal---------
    LEFT JOIN fu05_transaction ff
      ON ff.fu05_fu05_id = fu05.fu05_id
     AND ff.fu05_type IN (42,45)
     AND ff.fu05_status <> -1

    WHERE fu05.fu05_status = 1003
      AND fu05.fu05_type NOT IN (42,45)
      AND fu05.fu05_is_reversed = 0
      AND ff.fu05_id IS NULL
-----excluding reversal---------

    GROUP BY fu05.fu05_portfolio_id, fu05.fu05_pf06_id
)

SELECT /*+ PARALLEL(4) */
e.si04_id,fc.fund_Categ,
       SUM(t.holdings * nt.nav_value) amount
FROM txn t
JOIN nav_today nt
  ON t.fu05_pf06_id = nt.fu02_pf06_id
JOIN cr01_client_info c
  ON c.cr01_id = t.fu05_portfolio_id
JOIN emp e
  ON c.cr01_crm_no = e.portfolio_id
  join fund_Cat fc
  on fc.pf06_id = t.fu05_pf06_id
WHERE c.cr01_parent_id IS NOT NULL
GROUP BY e.si04_id,fc.fund_Categ
;
