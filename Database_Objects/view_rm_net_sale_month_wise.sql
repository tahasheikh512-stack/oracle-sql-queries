create or replace view view_rm_net_sale_month_wise as
select /*+ MATERIALIZE */
/*+ PARALLEL(4) */
 a.fu05_si04_id,to_char(NVL (a.FU05_MODIFIED_DATE, a.FU05_CREATED_DATE),'MON-YYYY') approval_date,
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
           end) gross_sale

  from fu05_transaction a
-----excluding reversal---------
  LEFT JOIN fu05_transaction ff
    ON ff.fu05_fu05_id = a.fu05_id
   AND ff.fu05_type IN (42, 45)
   AND ff.fu05_status <> -1

   AND a.fu05_type NOT IN (42, 45)
   AND a.fu05_is_reversed = 0
   AND ff.fu05_id IS NULL
-----excluding reversal---------
 where a.FU05_TYPE IN (1, 3, 4, 30)
   AND a.FU05_STATUS = 1003
      --   AND a.FU05_TYPE IN (1, 3, 4,30)
   AND a.FU05_APPROVAL_DATE IS NOT NULL
   AND (CASE
         WHEN a.fu05_Type = 1 AND a.Fu05_Allocation_DT IS NULL THEN
          DATE '1900-01-01'
         WHEN a.fu05_Type = 1 AND a.Fu05_Allocation_DT IS NOT NULL AND
              TRUNC(a.FU05_MODIFIED_DATE) IS NOT NULL THEN
          TRUNC(a.FU05_MODIFIED_DATE)
         ELSE
          TRUNC(a.FU05_APPROVAL_DATE)
       END) BETWEEN DATE '2026-01-01' AND SYSDATE

 group by a.fu05_si04_id,to_char(NVL (a.FU05_MODIFIED_DATE, a.FU05_CREATED_DATE),'MON-YYYY')
;
