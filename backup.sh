#!/bin/bash
# must run the script as oracle user!
#
#
# Execute
# echo "0 1 * * 2,4,6 oracle ${scripts}/run_alarm_backup.sh" >> /etc/crontab
# with the root user to add scheduled tasks
#
# Date: 2019/09/01 23:15
# Author:panjunbing@github

# directory
base='/backup/'
scripts="${base}scripts/"
log="${base}logs/"
rman="${base}rmam/"
# Archive retention day
archdate=1

mkdir -p ${scripts}
mkdir -p ${logs}
mkdir -p ${rman}

touch ${scripts}run_cemresult_backup.sh
touch ${scripts}cemresult_backup.sh
touch ${scripts}del_smnew_obsolete.rcv
touch ${scripts}smnew_full_backup.rcv
touch ${scripts}smnew_arch_backup.rcv
touch ${scripts}rman_validate_smnew.rcv
chmod u+x ${scripts}run_cemresult_backup.sh
chmod u+x ${scripts}cemresult_backup.sh
chmod u+x ${scripts}del_smnew_obsolete.rcv
chmod u+x ${scripts}smnew_full_backup.rcv
chmod u+x ${scripts}smnew_arch_backup.rcv
chmod u+x ${scripts}rman_validate_smnew.rcv

# run_backup script
echo "sh ${scripts}cemresult_backup.sh 1>/dev/null 2>&1" >  ${scripts}run_cemresult_backup.sh

# mian script
cat >> ${scripts}cemresult_backup.sh << EOF
source ~/.bash_profile
rman cmdfile=${scripts}del_smnew_obsolete.rcv log=${logs}del_smnew_obsolete.log
rman cmdfile=${scripts}smnew_full_backup.rcv log=${logs}smnew_full_backup.log
rman cmdfile=${scripts}smnew_arch_backup.rcv log=${logs}smnew_arch_backup.log
rman cmdfile=${scripts}rman_validate_smnew.rcv log=${logs}rman_validate_smnew.log
EOF

# first script
cat >> ${scripts}del_smnew_obsolete.rcv << EOF
connect target sys/oracle
DELETE force noprompt ARCHIVELOG UNTIL TIME "SYSDATE-${archdate}";
crosscheck backup of database;
crosscheck archivelog all;
delete force noprompt obsolete;
delete force noprompt expired backup;
delete force noprompt expired archivelog all;
exit;
EOF

# second script
cat >> ${scripts}smnew_full_backup.rcv << EOF
run
{
allocate channel c1 type disk maxpiecesize=2000M;
allocate channel c2 type disk maxpiecesize=2000M;
allocate channel c3 type disk maxpiecesize=2000M;
backup database tag='oracle_full_backup'
format "${rman}/full_database_%T_%U_full";
sql 'alter system archive log current';
release channel c1;
release channel c2;
release channel c3;
}
EOF

# thrid script
cat >> ${scripts}smnew_arch_backup.rcv << EOF
connect target sys/oracle
run
{
allocate channel c1 type disk maxpiecesize=2000M;
allocate channel c2 type disk maxpiecesize=2000M;
allocate channel c3 type disk maxpiecesize=2000M;
crosscheck archivelog all;
backup archivelog all
format "${rman}oracle_%T_%U_arc";
release channel c1;
release channel c2;
release channel c3;
}
EOF

# fourth script
cat >> ${scripts}rman_validate_smnew.rcv << EOF
connect target sys/oracle
RESTORE DATABASE VALIDATE;
RESTORE archivelog all VALIDATE;
exit;
EOF

cat ${scripts}run_cemresult_backup.sh
cat ${scripts}cemresult_backup.sh
cat ${scripts}del_smnew_obsolete.rcv
cat ${scripts}smnew_full_backup.rcv
cat ${scripts}smnew_arch_backup.rcv
cat ${scripts}rman_validate_smnew.rcv


# sudo echo "0 1 * * 2,4,6 oracle ${scripts}/run_alarm_backup.sh" >> /etc/crontab
