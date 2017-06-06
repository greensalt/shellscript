#!/bin/bash
# The script is used for Setting System Secure(SSH,USER,Conn_TimeOut,Disable ctrl+alt+del)
# By L.F.Xie On 2017-05-27

if which lsb_release > /dev/null;then
    :
else
    yum -y install redhat-lsb-core
fi

LOG_FILE="/tmp/system_init.log"
ROOT_PWD="T1y4%eZb7PjLh3"

## SSH Deny User Setting
SSH_CONF="/etc/ssh/sshd_config"
DENY_USERS="nagios lbs yanfa_ro mysql padm zabbix"

## SSH PASSWORD COMPLEXITY VERIFICATION
PAM_SYSTEM_CONF="/etc/pam.d/system-auth"

## LOCK USER
PAM_SSH_CONF="/etc/pam.d/sshd"

## SSH TIMEOUT SETTING
PROFILE_FILE="/etc/profile"

## Get OS Version
get_os_version(){
    OS_VERSION=`lsb_release -r|awk '{print $2}'`
    echo "$OS_VERSION"
}
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

## All Log
write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

## Check Result 0 or 1
check_result(){
    RESULT_VAL="$?"
    VELUE="$1"
    if [[ $RESULT_VAL != 0 ]];then
        write_log "[ Error ] $VELUE is failed."
    else
        write_log "[ Ok ] $VELUE is successful."
    fi
}

## Backup config
backup_file(){
    CONF_NAME="$1"
    DATETIME=`date +%F`
    BACKUP_NAME="${CONF_NAME}-${DATETIME}.bak"
    \cp -f ${CONF_NAME} ${BACKUP_NAME}
}

set_ssh(){

    PAM_OLD_SET="pam_cracklib.so try_first_pass retry=3"
    PAM_NEW_SET="pam_cracklib.so try_first_pass retry=3 dcredit=-1 ocredit=-1"
    LOCK_USER_SET="auth required pam_tally2.so onerr=fail deny=5 unlock_time=600"


    if [[ ! -f "$SSH_CONF" ]];then
        echo "How do you login ?"
        write_log "[ Error ] $SSH_CONF isn't exist."
        exit 2
    fi
    
    ## Deny User
    grep "^DenyUsers" $SSH_CONF > /dev/null 2>&1
    if [[ $? != 0 ]];then
        backup_file "$SSH_CONF"
        echo "DenyUsers $DENY_USERS" >> $SSH_CONF
        check_result "SSH DenyUsers"
    else
        write_log "SSH DenyUsers was setted"
    fi

    ## Pam Setting
    if [[ ! -f "$PAM_SYSTEM_CONF" ]];then
        write_log "[ Error ] $PAM_SYSTEM_CONF isn't exist."
        exit 2
    fi
    backup_file "$PAM_SYSTEM_CONF"
    
    grep "$PAM_OLD_SET" $PAM_SYSTEM_CONF|grep -v "^#" > /dev/null 2>&1
    if [[ $? == 0 ]];then
        sed -i "s/$PAM_OLD_SET .*/$PAM_NEW_SET/g" $PAM_SYSTEM_CONF
    else
        echo "password requisite $PAM_NEW_SET" >> $PAM_SYSTEM_CONF
    fi
    check_result "Set PAM in $PAM_SYSTEM_CONF"

    ## Lock User Setting
    backup_file "$PAM_SSH_CONF"
    grep "$LOCK_USER_SET" $PAM_SSH_CONF|grep -v "^#" > /dev/null 2>&1
    if [[ $? != 0 ]];then
        echo "$LOCK_USER_SET" >> $PAM_SSH_CONF
        check_result "Lock User Setting"
    else
        write_log "Lock User was Setted"
    fi

    ## SSH Base Set
    grep "^UseDNS no" $SSH_CONF > /dev/null
    if [[ $? == 0 ]];then
        write_log "$SSH_CONF was setted"
    else
        sed -i 's/^#UseDNS yes/UseDNS no/g' $SSH_CONF
        check_result "Set SSH 'UseDNS no' in $SSH_CONF"
        sed -i 's/^GSSAPIAuthentication yes/GSSAPIAuthentication no/g' $SSH_CONF
        check_result "Set SSH 'GSSAPIAuthentication no' in $SSH_CONF"
        sed -i 's/^GSSAPICleanupCredentials yes/GSSAPICleanupCredentials no/g' $SSH_CONF
        check_result "Set SSH 'GSSAPICleanupCredentials no' in $SSH_CONF"
    fi
    
}

## Connect TimeOut
set_profile(){
    CONN_TIMEOUT="export TMOUT=300"
    if [[ ! -f "$PROFILE_FILE" ]];then
        echo "No...!!! Can't be $PROFILE_FILE not exist."
        write_log "[ Error ] $PROFILE_FILE isn't exist."
        exit 2
    else
        backup_file "$PROFILE_FILE"
        grep "^export TMOUT=" $PROFILE_FILE > /dev/null 2>&1
        if [[ $? == 0 ]];then
            sed -i "s/export TMOUT=.*/$CONN_TIMEOUT/g" $PROFILE_FILE
        else
            echo "$CONN_TIMEOUT" >> $PROFILE_FILE
        fi
        check_result "Set $PROFILE_FILE Connect Timeout"
    fi
}

## Disable ctrl+alt+del
disable_ctrl_alt_del(){
    ## CentOS 6
    DISABLE_CONFIG="/etc/init/control-alt-delete.conf"

    if [[ ! -f "$DISABLE_CONFIG" ]];then
        write_log "$DISABLE_CONFIG is not exist"
    else
        sed -i 's/^exec/#&/' $DISABLE_CONFIG
        check_result "Disable 'Ctl+alt+del' in $DISABLE_CONFIG"
    fi
}

disable_iptables(){
    if [[ $SYSTEM_VERSION == 7 ]];then
        systemctl stop firewalld
        write_log "Stop iptables"
        systemctl disable firewalld
        write_log "Disable iptables run"
    else
        iptables -F
        iptables -X
        iptables -Z
        service iptables save
        service iptables stop
        chkconfig --level 2345 iptables off
        write_log "Disable iptables run"
    fi
}

set_root(){
    echo "$ROOT_PWD"|passwd --stdin root
}

set_ssh
set_profile
disable_ctrl_alt_del
disable_iptables
