CREATE OR REPLACE VIEW VIEW_RM_NET_SALE_DATA AS
select "NET_AMOUNT","GROSS_SALE","SI04_ID","FU05_APPROVAL_DATE" from (select /*+ MATERIALIZE */
/*+ PARALLEL(4) */
sum(((CASE
             WHEN a.FU05_TYPE IN (1,
                                  6,
                                  7,
                                  13,
                                  15,
                                  17,
                                  20,
                                  22,
                                  24,
                                  26,
                                  27,
                                  29,
                                  32,
                                  33,
                                  34,
                                  35,
                                  36,
                                  39,
                                  40,
                                  45,
                                  51,
                                  52,
                                  61,
                                  62,
                                  66,
                                  67,
                                  74,
                                  75,
                                  76,
                                  77,
                                  78,
                                  80) THEN
              1
             ELSE
              -1
           END) * DECODE(a.fu05_type,
                          43,
                          a.fu05_net_amount,
                          1,
                          a.fu05_total_nav,
                          a.fu05_net_amount))) net_amount,
       sum(case
             when a.fu05_type = 1 then
              a.fu05_net_amount
             else
              0
           end) gross_sale,
       nvl(a.fu05_si04_id,s.si04_id) si04_id, NVL (a.FU05_MODIFIED_DATE, a.FU05_CREATED_DATE) FU05_APPROVAL_DATE
  from fu05_transaction a,cr01_client_info c,cr01_client_info p,si04_employee s
   where a.fu05_portfolio_id = c.cr01_id
   and a.fu05_cr01_id = p.cr01_id
   and c.cr01_parent_id is not null
   and c.cr01_si04_id = s.si04_id(+)
   and a.fu05_is_reversed = 0
 and a.FU05_TYPE IN (1, 3, 4, 30)
   AND a.FU05_STATUS = 1003
   AND a.FU05_APPROVAL_DATE IS NOT NULL
   AND (CASE
         WHEN a.fu05_Type = 1 AND a.Fu05_Allocation_DT IS NULL THEN
          DATE '1900-01-01'
         WHEN a.fu05_Type = 1 AND a.Fu05_Allocation_DT IS NOT NULL AND
              TRUNC(a.FU05_MODIFIED_DATE) IS NOT NULL THEN
          TRUNC(a.FU05_MODIFIED_DATE)
         ELSE
          TRUNC(a.FU05_APPROVAL_DATE)
       END) BETWEEN DATE '2025-01-01' AND SYSDATE
        AND a.FU05_TYPE NOT IN (42, 45)
                     AND NOT EXISTS
                             -- Exclude reversal transactions
                             (SELECT NULL
                                FROM FU05_TRANSACTION FF
                               WHERE     FF.FU05_FU05_ID = a.FU05_ID
                                     AND FF.FU05_TYPE IN (42, 45)
                                     AND FF.FU05_STATUS <> -1)

 group by a.fu05_si04_id,s.si04_id,NVL (a.FU05_MODIFIED_DATE, a.FU05_CREATED_DATE))/*
 where  si04_id = 124013
 and FU05_APPROVAL_DATE between '01-jan-2026' and '12-may-2026'*/
;
