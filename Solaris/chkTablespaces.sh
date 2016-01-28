#!/bin/sh
#

# ------------------------------ SETTINGS --------------------------------------
ORACLE_SID=LAWPROD
ORACLE_HOME=/oracle/product/11.2.0/dbhome_1
ORACLE_USER="nagios"
ORACLE_PASS="nagios13"

# External commands
CMD_AWK="/usr/bin/awk"
CMD_EGREP="/usr/bin/egrep"

# Temporary work file (will be removed automatically)
#TEMP_FILE="/tmp/check_oracle_tablespace_$$.tmp"
TEMP_FILE="/tmp/check_oracle_tablespaces.tmp"
TEMP_FILE2="/tmp/check_oracle_tablespaces2.tmp"

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Default values
WARN_THRESHOLD=85
WARN_EXCEEDED=0
WARN_STATE_TEXT=""
WARN_P_EXCEEDED=0
CRIT_THRESHOLD=95
CRIT_EXCEEDED=0
CRIT_P_EXCEEDED=0
CRIT_STATE_TEXT=""

# ------------------------------ FUNCTIONS -------------------------------------

# Checks command line options (pass $@ as parameter).
checkOptions() {

    while getopts s:d:w:c:ailhvV OPT $@; do
            case $OPT in
                w) # warning threshold
                   opt_warn_threshold=$OPTARG
                   ;;
                c) # critical threshold
                   opt_crit_threshold=$OPTARG
                   ;;
            esac
    done

}
# ----------------------------- MAIN PROGRAM -----------------------------------

checkOptions $@

export ORACLE_SID
export ORACLE_HOME

if [ ! -x "$ORACLE_HOME/bin/sqlplus" ]; then
    echo "Error: $ORACLE_HOME/bin/sqlplus not found or not executable."
    exit $STATE_UNKNOWN
fi
$ORACLE_HOME/bin/sqlplus $ORACLE_USER/$ORACLE_PASS <<EOF | $CMD_EGREP "LINIA" > $TEMP_FILE
set linesize 80
set pages 500
set head off

column tablespace_name format a20
column usage_pct       format 999
column freeMB          format 99999

break on report

select 'LINIA' Filtro, t.tablespace_name, round(100-100*(nvl(f.MB,0)+t.MAXMB-t.MB)/t.MAXMB) usage_pct, nvl(f.MB,0) freeMB
from
 ( select tablespace_name, round(sum(bytes)/1024/1024) MB,
   round(sum(decode(autoextensible, 'NO', bytes, maxbytes))/1024/1024) MAXMB
   from dba_data_files df where tablespace_name in
   (select tablespace_name from dba_tablespaces where contents='PERMANENT')
   group by tablespace_name) t
 left outer join
 (select tablespace_name, round(sum(bytes)/1024/1024) MB
 from dba_free_space2 group by tablespace_name) f
 on t.tablespace_name=f.tablespace_name
where round(100-100*(nvl(f.MB,0)+t.MAXMB-t.MB)/t.MAXMB)>80
order by usage_pct desc
/
EOF


##FILTR TABLESPACE_NAME                 USAGE_PCT     FREEMB
##----- ------------------------------ ---------- ----------
##LINIA PRAN8HIST_D1                           97        115
##LINIA USTEST_I1                              96        249
##LINIA LDF8_I1                                95       1670
##LINIA LDF8_D1                                94       1987
##LINIA USTEST_D1                              92        485
##LINIA PRAN8HIST_I1                           89        564
##LINIA MEX_D1                                 89       1446
##LINIA MEXTEST_I1                             86       4179
##LINIA CHILE9_D1                              83       1500
##LINIA AJUSTES_D1                             81        541
##LINIA AREAUSA9_D1                            81       1479

#if [ "`cat $TEMP_FILE`" = "" ]; then
if [ ! -s $TEMP_FILE ]; then
    echo "Error: Empty result from sqlplus. Check plugin settings and Oracle status."
    exit $STATE_UNKNOWN
fi
# Loop through tablespace usage percentages and set a flag if thresholds
# are exceeded.
#
column=0
aetext=""
for row in `cat $TEMP_FILE`; do
    column=`expr $column + 1`
    case $column in
        1) # Filtro
           filtro=$row
           ;;
        2) # tablespace name
           ts=$row
           ;;
        3) # usage percentage
           usage=$row
           ;;
        4) # free MB
           freeMB=$row
           # Reset column.
           column=0

# echo "${ts} usage:${usage}  freeMB:${freeMB}  Crit.Threshold:  $CRIT_THRESHOLD "

          if [ $usage -gt $CRIT_THRESHOLD ] && [ $freeMB -lt 1000 ] ; then
					
              # Critical threshold was exceeded.
              CRIT_EXCEEDED=1
              
			  ##fer la consulta
				$ORACLE_HOME/bin/sqlplus $ORACLE_USER/$ORACLE_PASS <<EOF | grep LINIA > $TEMP_FILE2
set linesize 80
set pages 500
set head off
column warning       format 99

break on report

select 'LINIA' Filtro, CRITICAL from tablespace_thresholds where tablespace_name='${ts}'
/
EOF
			  if [ ! -s $TEMP_FILE2 ]; then
				if [ "$CRIT_STATE_TEXT" != "" ]; then
					CRIT_STATE_TEXT="${CRIT_STATE_TEXT}; ${ts} ${aetext}${usage}%"
				else
					CRIT_STATE_TEXT="${CRIT_STATE_TEXT}${ts} ${aetext}${usage}%"
				fi
			  else
				for row in `cat $TEMP_FILE`; do
					filtro=$row
					ts=$row
				done
			  fi
			  

			  ##si esta buida es fa el mateix
			  
			  ##si esta plena canvia
			  
			  if [ "$CRIT_STATE_TEXT" != "" ]; then
                CRIT_STATE_TEXT="${CRIT_STATE_TEXT}; ${ts} ${aetext}${usage}%"
              else
                CRIT_STATE_TEXT="${CRIT_STATE_TEXT}${ts} ${aetext}${usage}%"
              fi

           elif [ $usage -gt $WARN_THRESHOLD ] && [ $freeMB -lt 1000 ] ; then
              # Warning threshold was exceeded.
              WARN_EXCEEDED=1
			  
			  //fer la consulta propia
			  
              if [ "$WARN_STATE_TEXT" != "" ]; then
                WARN_STATE_TEXT="${WARN_STATE_TEXT}; ${ts} ${aetext}${usage}%"
              else
                WARN_STATE_TEXT="${WARN_STATE_TEXT}${ts} ${aetext}${usage}%"
              fi
           fi
           ;;
    esac
done

# Remove temporary work file.
rm -f $TEMP_FILE

# Print check results and exit.
if [ $CRIT_EXCEEDED -eq 1 ]; then
    if [ $WARN_EXCEEDED -eq 1 ]; then
        echo "TABLESPACE CRITICAL: $CRIT_STATE_TEXT WARNING: $WARN_STATE_TEXT"
    else
        echo "TABLESPACE CRITICAL: $CRIT_STATE_TEXT"
    fi
    exit $STATE_CRITICAL

elif [ $WARN_EXCEEDED -eq 1 ]; then
    echo "TABLESPACE WARNING: $WARN_STATE_TEXT"
    exit $STATE_WARNING
fi

echo "TABLESPACE OK"
exit $STATE_OK




select CRITICAL FROM tablespace_thresholds where tablespace_name='PRAN8HIST_D1';
select WARNING FROM tablespace_thresholds where tablespace_name='PRAN8HIST_D1';
 

INSERT INTO "NAGIOS"."TABLESPACE_THRESHOLDS" (TABLESPACE_NAME, WARNING, CRITICAL) VALUES ('PRAN8HIST_D1', '98', '99')
INSERT INTO "NAGIOS"."TABLESPACE_THRESHOLDS" (TABLESPACE_NAME, WARNING, CRITICAL) VALUES ('USTEST_I1', '98', '99')
INSERT INTO "NAGIOS"."TABLESPACE_THRESHOLDS" (TABLESPACE_NAME, WARNING, CRITICAL) VALUES ('USTEST_D1', '94', '96')
INSERT INTO "NAGIOS"."TABLESPACE_THRESHOLDS" (TABLESPACE_NAME, WARNING, CRITICAL) VALUES (' PRAN8HIST_I1', '94', '96')
