CREATE OR REPLACE VIEW VIEW_RM_NET_LOAD_DATA AS
select "SI04_ID","NET_LOAD","TRADE_DATE_TIME"
  from (select /*+ MATERIALIZE */
        /*+ PARALLEL(t, 4) */
         case
           when fu05_si04_id is not null then
            fu05_si04_id
           else
            si04_id
         end SI04_ID,

         sum(net_load) net_load,TRADE_DATE_TIME

          from (select SI04_ID, fu05_si04_id, sum(net_load) net_load,TRADE_DATE_TIME
                  from (SELECT

                         (CASE
                           WHEN (FRONT_LOAD + SWITCH_IN + SST) > 0 THEN
                            (FRONT_LOAD + SWITCH_IN)
                           ELSE
                            0
                         END) + nvl(value_amount, 0) NET_LOAD,
                         (REDEMPTION_FEE + CONTINGENT_FEE + SWITCH_OUT) EXIT_LOAD,

                         SI04_ID,
                         fu05_si04_id,

                         TRADE_DATE_TIME,
                         to_number(to_char(TRADE_DATE_TIME, 'MM')) TRADE_Month,
                         to_number(to_char(TRADE_DATE_TIME, 'YYYYMMDD')) TRADE_SQNO,
                         to_char(TRADE_DATE_TIME, 'MON') TRADE_MON,
                         to_number(to_char(TRADE_DATE_TIME, 'YYYY')) TRADE_YR

                          FROM (SELECT

                                 TRUNC(FU05.FU05_NAV_DATE) DEAL_DATE,
                                 TO_CHAR(FU05.FU05_APP_DATETIME, 'Mon') TRANS_MONTH,

                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 3 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) FRONT_LOAD,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 81 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) SWITCH_IN,
                                 --
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 4 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) REDEMPTION_FEE,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 22 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) CONTINGENT_FEE,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 82 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) SWITCH_OUT,
                                 --
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 19 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) SST,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 70 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) ZAKAT_AMT,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 20 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) CGT,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 29 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) + SUM(CASE
                                                  WHEN FU39.FU39_FEE_TYPE = 28 THEN
                                                   FU39.FU39_AMOUNT
                                                  ELSE
                                                   0
                                                END) +
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 30 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) TRANS_COST,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE = 29 THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) PAC,
                                 SUM(CASE
                                       WHEN FU39.FU39_FEE_TYPE IN (21, 83) THEN
                                        FU39.FU39_AMOUNT
                                       ELSE
                                        0
                                     END) DIVIDEND,

                                 FU05.fu05_si04_id,
                                 SI04.SI04_ID,

                                 NVL(FU05_MODIFIED_DATE, FU05_CREATED_DATE) TRADE_DATE_TIME,
                                 (select fu1.fu05_value_amount
                                    from fu05_transaction fu1
                                   where fu1.fu05_type in (18)
                                     and fu1.fu05_id = fu05.fu05_id) value_amount

                                  FROM FU05_TRANSACTION FU05,
                                       CR01_CLIENT_INFO CR01,
                                       SI04_EMPLOYEE    SI04,
                                       PF06_INSTANCE    PF06,
                                       CR01_CLIENT_INFO CR01_P,
                                       FU39_FEE_CHARGES FU39
                                 WHERE FU05_PORTFOLIO_ID = CR01.CR01_ID
                                   AND FU05_CR01_ID = CR01_P.CR01_ID
                                   AND FU05_PF06_ID = PF06_ID
                                   AND CR01.CR01_PARENT_ID IS NOT NULL
                                   AND FU05_STATUS = 1003
                                   and FU05_TYPE in (1, 13, 18)

                                   AND FU05_APPROVAL_DATE is not null
                                   AND (CASE
                                         WHEN fu05_Type = 1 AND
                                              Fu05_Allocation_DT is null THEN
                                          DATE '1900-01-01'
                                         WHEN fu05_Type = 1 AND
                                              Fu05_Allocation_DT is not null and
                                              TRUNC(FU05_MODIFIED_DATE) is not null THEN
                                          Trunc(FU05_MODIFIED_DATE)
                                         ELSE
                                          Trunc(FU05_APPROVAL_DATE)
                                       END) between DATE
                                 '2025-01-01'
                                   aND sysdate

                                   AND FU05_ID = FU39_FU05_ID(+)

                                   AND CR01.CR01_SI04_ID = SI04_ID(+)

                                   AND FU05.FU05_TYPE NOT IN (42, 45)
                                   AND NOT EXISTS
                                 (SELECT NULL
                                          FROM FU05_TRANSACTION FF
                                         WHERE FF.FU05_FU05_ID = FU05.FU05_ID
                                           AND FF.FU05_TYPE IN (42, 45)
                                           AND FF.FU05_STATUS <> -1) -- EXCLUDE REVERSAL TRANSACTIONS
                                 GROUP BY TRUNC(FU05.FU05_NAV_DATE),
                                          TO_CHAR(FU05.FU05_APP_DATETIME, 'Mon'),
                                          FU05_MODIFIED_DATE,
                                          FU05_CREATED_DATE,
                                          fu05.fu05_id,
                                          FU05.fu05_si04_id,
                                          SI04.SI04_ID) TAB) dd

                 group by SI04_ID,
                          fu05_si04_id,

                          TRADE_DATE_TIME)
         group by case
                    when fu05_si04_id is not null then
                     fu05_si04_id
                    else
                     si04_id
                  end,TRADE_DATE_TIME)
;
