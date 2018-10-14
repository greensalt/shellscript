#!/bin/bash
# The script is used for Cleanup Traces
# By xielifeng On 2016-07-05

source ./public.sh

ERR_CONTENT=`grep -i 'error' $LOG_FILE`
if [[ -n "$ERR_CONTENT" ]];then
    alert "[ Error ] Init Failed"
    exit 1
else
    alert "[ Ok ] Init finished"
    check_result "Alert Init Finished"
    rm -f $SPATH/* && rm -f $SPATH/../`basename $SPATH`.tar.gz
    check_result "Del All"
    write_log "reboot"
    reboot
fi

