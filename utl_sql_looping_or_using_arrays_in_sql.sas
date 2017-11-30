SAS Forum:  Looping or using arrays within SQL (do_over macro)

Note there are three macros in this post

  REQUIRED  MACROS:

        NUMLIST -- if using numbered lists in VALUES parameter.
        ARRAY   -- if using macro arrays.
        DO_OVER -- patemt macro


PROBEM: I Need to generate this text to include in a SQL select clause.

     (exp(sum(log(1+FOOD/100))))-1 as FOOD1 format=percent8.2
    ,(exp(sum(log(1+WATER/100))))-1 as WATER1 format=percent8.2
    ,(exp(sum(log(1+SODA/100))))-1 as SODA1 format=percent8.2
    ,(exp(sum(log(1+JUNKFOOD/100))))-1 as JUNKFOOD1 format=percent8.2


INPUT
=====

  %array(foods,values=food water soda junkfood)

  WORK.HAVE total obs=1

   FOOD    WATER    SODA    JUNKFOOD    YR    WK    DAY    DATES

     1       1        0         0        1     1     1       1

WORKING CODE two solutions
==========================

 1.  %do_over(foods,between=%str(,),phrase=(exp(sum(log(1+?/100))))-1 as ?1 format=percent8.2)


 2.  The key is understanding ifc(dosubl during phase one compile

     If the result of the dosubl is 0 then the text 'want' is inserted
     into sql 'from' clause AND the dataset work.want will exist.
     The ouside SQL can now use the want dataset.

     by Quentin McMullen via listserv.uga.edu .
     If SAS integrates dosubl this could become the preferred solution.

     proc sql;   * bad performance;
        select
           *
        from
           %sysfunc(ifc(
              %sysfunc(dosubl(%nrstr(
                 proc sort data=have out=_temp;
                    by yr wk day;
                 run;quit;
                 data want;
                 array _s{99};
                 do until(last.wk);
                     set _temp; by yr wk;
                     array ind food -- JUNKFOOD;
                     do i = 1 to dim(ind);
                         _s{i} = sum(_s{i}, log(1+(ind{i}/100)));
                         end;
                     end;
                 do i = 1 to dim(ind);
                     ind{i} = exp(_s{i}) - 1;
                     end;
                 drop i _s: ;
                 run;)))=0      * if dosubl sucessful then insert want text;
                ,want
                ,
              ));
     quit;


OUTPUT
======

   WORK.WANT total obs=1                                             **** COMPUTED VALUES ****************

    FOOD    WATER    SODA    JUNKFOOD    YR    WK    DAY    DATES    FOOD1    WATER1    SODA1    JUNKFOOD1

      1       1        0         0        1     1     1       1       0.01     0.01       0          0

post
https://communities.sas.com/t5/Base-SAS-Programming/Looping-or-using-array-within-Proc-sql/m-p/417279

PSStats profile
https://goo.gl/UH1M4a
https://communities.sas.com/t5/user/viewprofilepage/user-id/462


SOAPBOX ON

   Over 11 years of using this macro because SAS
   will not give us an open code %do?

SOAPBOX OFF

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

data have;
  retain food 1 water 1 soda 0 junkfood 0 yr 1 wk 1 day 1 dates 1;
run;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __
/ __|/ _ \| | | | | __| |/ _ \| '_ \
\__ \ (_) | | |_| | |_| | (_) | | | |
|___/\___/|_|\__,_|\__|_|\___/|_| |_|

;

*    _
  __| | ___     _____   _____ _ __
 / _` |/ _ \   / _ \ \ / / _ \ '__|
| (_| | (_) | | (_) \ V /  __/ |
 \__,_|\___/___\___/ \_/ \___|_|
          |_____|
;

%symdel foods / nowarn;
proc sql;
  create table want  as
  select *
     %array(foods,values=food water soda junkfood)
    ,%do_over(foods,between=%str(,),phrase=(exp(sum(log(1+?/100))))-1 as ?1 format=percent8.2)
  from HAVE
  group by YR, WK
  having DAY=max(day)
  order by DATES ;
quit;

*          _       _       _            _
 ___  __ _| |   __| | __ _| |_ __ _ ___| |_ ___ _ __
/ __|/ _` | |  / _` |/ _` | __/ _` / __| __/ _ \ '_ \
\__ \ (_| | | | (_| | (_| | || (_| \__ \ ||  __/ |_) |
|___/\__, |_|  \__,_|\__,_|\__\__,_|___/\__\___| .__/
        |_|                                    |_|
;

proc sql;
   select
      *
   from
      %sysfunc(ifc(
         %sysfunc(dosubl(%nrstr(
            proc sort data=have out=_temp;
               by yr wk day;
            run;quit;
            data want;
            array _s{99};
            do until(last.wk);
                set _temp; by yr wk;
                array ind food -- JUNKFOOD;
                do i = 1 to dim(ind);
                    _s{i} = sum(_s{i}, log(1+(ind{i}/100)));
                    end;
                end;
            do i = 1 to dim(ind);
                ind{i} = exp(_s{i}) - 1;
                end;
            drop i _s: ;
            run;)))=0
           ,want
           ,
           ))
           ;
quit;

