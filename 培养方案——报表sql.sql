

--****************************************************************************************************
--****************************************************************************************************
--************1.打印-培养计划管理-1-哈工大（深圳）学生个人培养计划.doc********************************
--************入参统一为：学号（XH）                                  ********************************
--****************************************************************************************************
--****************************************************************************************************
--第一部分、表头学生基本信息查询
--字段：学号、姓名、专业代码、学位类型代码、专业名称、专业名称英文、学位类型名称、学位类型名称英文
SELECT T1.XH,T1.XM,T1.ZYXKM,T1.XWLBM,T2.ZYMC,T2.ZYMC_EN, T3.MC XWLXMC,T3.MC_EN XWLXMC_EN
FROM T_XJ_XSXXB T1 
     LEFT JOIN T_DM_XKZYB T2 ON T1.ZYXKM=T2.ZYDM AND T1.PYLX=T2.PYLX
     LEFT JOIN T_DM_XWLBB T3 ON T1.XWLBM=T3.DM
WHERE XH='18S054243';

--第二部分、学生个人培养计划课程查询
--字段：课程类别代码、课程类别名称、课程列表名称英文、课程代码、课程名称、课程名称英文、学时、学分、推荐开课学期代码、推荐开课学期、开课单位代码、开课单位名称、开课单位名称英文
SELECT T1.DM KCLBDM,T1.MC KCLBMC,T1.YWMC KCLBMC_EN,T.KCDM,T.KCMC,T.KCYWMC KCMC_MC,T.SJZXS,T.XF,T.TJKKXNXQ,T2.XQMC,T2.XQMC_EN,T.KKXYDM,T3.YXMC,T3.YXMC_EN
FROM T_PY_XSFA_XSPYFAKCB T 
LEFT JOIN T_KCK_DM_KCLBB T1 ON T.KCLBDM=T1.DM AND T.PYLB=T1.PYLB
LEFT JOIN (SELECT  XQ,XQMC,XQMC_EN FROM T_DM_XNXQB T GROUP BY XQ,XQMC,XQMC_EN) T2 ON T.TJKKXNXQ=T2.XQ
LEFT JOIN T_DM_YXB T3 ON T.KKXYDM=T3.YXDM
WHERE XH='18S054243'
ORDER BY T.KCDM;

--第三部分、统计学生个人计划课程总学分
select sum(xf) zxf
from t_py_xsfa_xspyfakcb
where xh='18S054243';



--****************************************************************************************************
--****************************************************************************************************
--******************************1.统计-开课计划表格-1-开课计划查询.xls********************************
--******************************入参统一为：学年学期（xnxq）          ********************************
--****************************************************************************************************
--****************************************************************************************************
--字段：学年学期、开课院系、课程代码、课程名称、课程负责人、培养层次、显示总学时、显示理论学时、显示实验学时、学分、课程类别名称、开课状态（1开课 其他停课）、授课教师、考核方式
SELECT T2.XNMC||T2.XQMC XNXQ, T3.YXMC KKYX,T4.KCDM,T4.KCMC,T5.JSXM KCFZR,
       (SELECT REGEXP_REPLACE(LISTAGG(NVL(A3.MC, ''), ',') WITHIN GROUP(ORDER BY KCDM,A3.DM), '([^,]+)(,\1)*(,|$$)','\1\3') PYCC
		FROM T_PY_ZDXFA_FAXXB A1 LEFT JOIN T_PY_ZDXFA_FAKCB A2 ON A1.FAH=A2.FAH
		LEFT JOIN T_DM_PYCCB A3 ON A1.PYCC=A3.DM AND A3.PYLX='2'
		WHERE A1.BBH=T1.BBH AND A2.KCID=T1.KCID )PYCCMC,
       T6.XSZXS,T6.XSLLXS,T6.XSSYXS,T6.XF,
       (SELECT MC FROM T_KCK_DM_KCLBB WHERE DM=T6.KCLBDM)KCLBMC,T1.QRZT SFKK,
       (SELECT LISTAGG(NVL(B.JSXM, ''), ',') WITHIN GROUP(ORDER BY KCID)  FROM T_KCK_KCSKCYB A  LEFT JOIN T_SZ_JSXXB B ON A.CYDM = B.ID WHERE A.KCID = T1.KCID) SKJS,
       (SELECT MC FROM T_KCK_DM_KCKSFSB WHERE DM=T6.KHFSDM) KHFSMC, T1.BBH
FROM T_PY_XQJH_JHKCB T1 
LEFT JOIN T_DM_XNXQB T2 ON T1.KKXN||T1.KKXQ=T2.XN||T2.XQ
LEFT JOIN T_DM_YXB T3 ON T1.KKYX=T3.YXDM
LEFT JOIN T_KCK_KCJBXXB T4 ON T1.KCID=T4.KCID
LEFT JOIN T_SZ_JSXXB T5 ON T4.KCFZR=T5.ZGH
LEFT JOIN T_PY_ZDXFA_FAKCB T6 ON T1.KCID=T6.KCID AND T1.FAH=T6.FAH
WHERE ZTDM='99' AND T1.PYLB='2' AND  T1.KKXN||T1.KKXQ= '2018-20191'
ORDER BY T1.KKYX,T6.KCLBDM,T6.KCDM;


--****************************************************************************************************
--****************************************************************************************************
--******************************统计-开课计划表格-1-开课计划查询.xls**********************************
--******************************入参统一为：学年学期（xnxq）          ********************************
--****************************************************************************************************
--****************************************************************************************************
--字段：学年学期、开课院系、课程代码、课程名称、课程负责人、培养层次、显示总学时、显示理论学时、显示实验学时、学分、课程类别名称、开课状态（1开课 其他停课）、授课教师、考核方式、年级、上课学院、上课专业
SELECT T2.XNMC||T2.XQMC XNXQ, T3.YXMC KKXY,T4.KCDM,T4.KCMC,T5.JSXM KCFZR,
       '本科' PYCCMC,T6.XSZXS,T6.XSLLXS,T6.XSSYXS,T6.XF,
       (SELECT MC FROM T_KCK_DM_KCLBB WHERE DM=T6.KCLBDM)KCLBMC,T1.QRZT SFKK,
       (SELECT  LISTAGG(NVL(B.JSXM, ''), ',') WITHIN GROUP(ORDER BY KCID)  FROM T_KCK_KCSKCYB A  LEFT JOIN T_SZ_JSXXB B ON A.CYDM = B.ID WHERE A.KCID = T1.KCID) SKJS,
       (SELECT MC FROM T_KCK_DM_KCKSFSB WHERE DM=T6.KHFSDM) KHFSMC,T1.NJ,
       (SELECT YXMC FROM T_DM_YXB WHERE YXDM=T1.YXDM) SKXY,
       (SELECT ZYMC FROM T_DM_XKZYB WHERE ZYDM=T1.ZYDM AND PYLX='1' ) ZYMC
FROM T_PY_XQJH_JHKCB T1 
LEFT JOIN T_DM_XNXQB T2 ON T1.KKXN||T1.KKXQ=T2.XN||T2.XQ
LEFT JOIN T_DM_YXB T3 ON T1.KKYX=T3.YXDM
LEFT JOIN T_KCK_KCJBXXB T4 ON T1.KCID=T4.KCID
LEFT JOIN T_SZ_JSXXB T5 ON T4.KCFZR=T5.ZGH
LEFT JOIN T_PY_NJFA_FAKCB T6 ON T1.KCID=T6.KCID AND T1.FAH=T6.FAH
WHERE ZTDM='99'  AND T1.PYLB='1' AND  T1.KKXN||T1.KKXQ= '2018-20191'
ORDER BY T1.KKYX,T6.KCLBDM,T6.KCDM;



--****************************************************************************************************
--****************************************************************************************************
--******************************统计-任务管理表格-3-教学计划通知书.xls********************************
--******************************入参统一为：学年学期（xnxq）          ********************************
--***************************************** 年级、上课学院、专业      ********************************
--****************************************************************************************************
--字段：学年学期、开课院系、课程代码、课程名称、显示总学时、显示理论学时、显示实验学时、学分、课程类别名称、考核方式、年级、上课学院、上课专业、班级名称
SELECT T2.XNMC||T2.XQMC XNXQ, T3.YXMC KKXY,T4.KCDM,T4.KCMC,
       T6.XSZXS,T6.XSLLXS,T6.XSSYXS,T6.XF,
       (SELECT MC FROM T_KCK_DM_KCLBB WHERE DM=T6.KCLBDM)KCLBMC,
       (SELECT MC FROM T_KCK_DM_KCKSFSB WHERE DM=T6.KHFSDM) KHFSMC,T1.NJ,
       (SELECT YXMC FROM T_DM_YXB WHERE YXDM=T1.YXDM) SKXY,
       (SELECT ZYMC FROM T_DM_XKZYB WHERE ZYDM=T1.ZYDM AND PYLX='1' ) ZYMC,
       (SELECT  LISTAGG(NVL(BJMC, ''), ',') WITHIN GROUP(ORDER BY NJ,YXDM,ZYDM)  FROM T_DM_BJB WHERE YXDM = T1.YXDM AND ZYDM=T1.ZYDM AND NJ=T1.NJ) BJMC
FROM T_PY_XQJH_JHKCB T1 
LEFT JOIN T_DM_XNXQB T2 ON T1.KKXN||T1.KKXQ=T2.XN||T2.XQ
LEFT JOIN T_DM_YXB T3 ON T1.KKYX=T3.YXDM
LEFT JOIN T_KCK_KCJBXXB T4 ON T1.KCID=T4.KCID
LEFT JOIN T_PY_NJFA_FAKCB T6 ON T1.KCID=T6.KCID AND T1.FAH=T6.FAH
WHERE ZTDM='0'  AND T1.PYLB='1' AND T1.QRZT='1' AND T1.KKXN||T1.KKXQ= '2018-20191'
AND T1.NJ='2018' AND T1.YXDM='039999' AND T1.ZYDM='080'
ORDER BY T1.KKYX,T6.KCLBDM,T6.KCDM;




 select kclbb.mc,t.kcnum from t_kck_dm_kclbb kclbb left join
   (select KCLB,count(1) kcnum from t_rw_rwapb where xn='2017-2018' and xq='1' and sftk='0' group by kclb) t
   on kclbb.dm=t.kclb
   order by kclbb.dm



select yxb.yxmc,kclbb.mc kclbmc,count(1) num from t_rw_rwapb t left join t_dm_yxb yxb on t.kkyx=yxb.yxdm 
   left join t_kck_dm_kclbb kclbb on  t.kclb=kclbb.dm where kclbb.mc is not null
   and xn='2017-2018' and xq='1' and sftk='0'
   group by yxb.yxmc,kclbb.mc 


