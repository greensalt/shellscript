#!/bin/bash
# By L.F.Xie On 2017-06-29

SPATH=`cd $(dirname $0);pwd`
LOG_DIR="$SPATH/logs"
LOG_FILE="$LOG_DIR/$(basename $0).log"
[ ! -d "$LOG_DIR" ] && mkdir  $LOG_DIR
[ ! -f "$LOG_FILE" ] && touch $LOG_FILE

## Alert
alert(){
    MSG_BODY="$1"
    receiver="aaa@sss.com,bbb@sss.com"
    TITLE="Salt已执行,请联系管理员添加基础监控."
    USERNAME="nagios"
    PASSWORD="nagios"
    ALERT_SMS_URL="http://ow.aaaa.com:3889/mail_sms/mail.php"
    curl -d  "notify_receiver=$receiver&notify_title=${TITLE}&notify_body=${MSG_BODY}&user_name=${USERNAME}&user_passwd=${PASSWORD}" $ALERT_SMS_URL
}

## All Log
write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

## Clean LOG
CLEAN_LOG(){
    YESTERDAY=`date +%F -d "-1day"`
    N_LOG="$LOG_FILE.${YESTERDAY}"
    mv $LOG_FILE $N_LOG
    find $LOG_DIR -atime +10 -exec rm -f {} \;
}      

check_result(){
    FILE="$1"
    ITEM=`basename $FILE|awk -F '.' '{print $1}'`
    FAILED_NUM=`grep -A 5 'Summary' $FILE |grep Failed:|awk '{print $2}'`
    if [[ $FAILED_NUM == 0 ]];then
        write_log "[ OK ] $ITEM run successful."
    else
        write_log "[ ERROR ] $ITEM run failed."
    fi
}

while true
do
    echo "------------------ `date +%T`"
    SALT_ID_LIST="`salt-key -l 'un'|awk 'NR!=1{print}'`"
    if [ -z "$SALT_ID_LIST" ];then
        sleep 60
        continue
    else
        write_log "New Salt_id is <$SALT_ID_LIST>"
    fi

    salt-key -A -y
    write_log "Accept Salt_id <$SALT_ID_LIST>, and sleep 360s."
    sleep 360
    write_log "Sleep 360s over."
    for ID in $SALT_ID_LIST
    do
        LDAP_TMP="$LOG_DIR/ldap.tmp"
        RMDB_TMP="$LOG_DIR/rmdb.tmp"
        write_log "============= Start [ $ID ] ============="
        salt $ID state.sls pro.ldap.ldap > $LDAP_TMP
        check_result "$LDAP_TMP"
        cat $LDAP_TMP >> $LOG_FILE
        write_log "Command {salt $ID state.sls pro.ldap.ldap} run finished."
        sleep 2
        salt $ID state.sls pro.rmdb.rmdb > $RMDB_TMP
        check_result "$RMDB_TMP"
        cat $LDAP_TMP >> $LOG_FILE
        write_log "Command {salt $ID state.sls pro.rmdb.rmdb} run finished."
        sleep 2
        salt $ID saltutil.sync_modules
        write_log "Command {salt $ID saltutil.sync_modules} run finished."
        write_log "============= End [ $ID ] ============="
    done

    alert "$SALT_ID_LIST"
done
