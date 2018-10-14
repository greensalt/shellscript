#!/bin/bash
# The script is used for Test Init All Setting.
# By xielifeng On 2016-07-22

source ./public.sh

check_user_add(){
    for OS_USER in `cat $PASSWD_FILE|grep -v '^#'|awk '{print $1}'`
    do
        id $OS_USER > /dev/null 2>&1
        check_result "Check $OS_USER"
    done
}

process_test(){
    PRO_NAME="$1"
    [[ -z "$PRO_NAME" ]] && write_log "[ Error ] Process is Null" && exit 2
    ps -ef|grep $PRO_NAME|grep -v grep > /dev/null 2>&1
}

check_service(){
    SERVICES="salt-minion zabbix nrpe gmond"
    for SERVICE in $SERVICES
    do
        process_test "$SERVICE"
        check_result "Check $SERVICE"
    done
}

write_log "---------------- Check Init ---------------"
check_user_add
check_service
