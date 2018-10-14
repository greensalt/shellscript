#!/bin/bash
# By xielifeng On 2016-06-27

if which lsb_release > /dev/null;then
    :
else
    yum -y install redhat-lsb-core
fi

source ./public.sh

[[ -f "$LOG_FILE" ]] && rm -f $LOG_FILE

if [[ -f "$SN_TXT" ]];then
    echo "[ Error ] $SN_TXT is exist,deny init"
    write_log "[ Error ] $SN_TXT is exist,deny init"
    alert "[ Error ] $SN_TXT is exist,deny init"
    exit 2
fi

check_err(){
    grep 'Error' $LOG_FILE > /dev/null
    if [[ $? == 0 ]];then
        Err_Con="`awk '/Error/{print}' $LOG_FILE` Exit."
        echo "$Err_Con"
        alert "$Err_Con"
        exit 2
    fi
}

bash ./yum_setting.sh
check_err
bash ./base.sh
check_err
bash ./add_route.sh
check_err
bash ./rmdb_status.sh
check_err
bash ./user_init.sh
check_err
bash ./system_setting.sh
check_err
bash ./system_secure_setting.sh
check_err
bash ./salt_install.sh
check_err
bash ./soft_install.sh
check_err
bash ./monitor.sh
check_err
bash ./ldap_install.sh
check_err
bash ./rmdb_get_device_info.sh
check_err
bash ./rmdb_update_device_info.sh
check_err
# bash ./install_frigga.sh
# check_err
bash ./del_all.sh
