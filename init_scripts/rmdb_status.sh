#!/bin/bash
# The script is used for getting RMDB status
# By xielifeng On 2016-07-01

source ./public.sh

get_rmdb_status(){

    check_rmdb_url

    # Ok json core: {"status": "online", "sn": "CN-ZJXL-02000919"}
    # Error json core: {"1": "Error:no server or server status is null"}

    RMDB_API_ARG="api/get_sn_status_by_ip"
    RMDB_URL_API="$RMDB_URL/$RMDB_API_ARG"
    GET_HOST_INFO=`curl -k -s -d "{\"ex_ip\":\"$(get_ip)\", \"flag\":\"$(get_flag)\"}" "$RMDB_URL/$RMDB_API_ARG"`

    echo "$GET_HOST_INFO"|grep -i "Error" > /dev/null 2>&1
    if [[ $? == 0 ]];then
        echo "[ Error ] Rmdb get $(get_ip) info failed"
        write_log "[ Error ] Rmdb get $(get_ip) info failed"
        exit 2
    fi

    HOST_STATUS=`echo "$GET_HOST_INFO"|awk -F ':|,' '/status/{print $2}'|tr -d '"'`
    HOST_ID=`echo "$GET_HOST_INFO"|awk -F ',' '{print $2}'|tr -d '"|}'|awk -F ':' '{print $2}'`

    if [[ "$HOST_STATUS" == "uninit" || "$HOST_STATUS" == "idle2" ]];then
        echo "OK: Host status is uninit, Allow init"
        write_log "[ Ok ]: Host status is uninit, Allow init"
        write_log "-------------- Begin Init ---------------"
    else
        echo "ERROR: Host status is $HOST_STATUS, Deny init"
        write_log "[ Error ] Host status is $HOST_STATUS, Deny init" 
        exit 2
    fi
    
}
get_rmdb_status
