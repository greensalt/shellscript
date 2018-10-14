#!/bin/bash
# The script is used for Provide Public Function
# By xielifeng On 2016-06-27

## Set Global Env
PATH_0="$PATH:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin"
PATH_1="`echo $PATH_0|tr ':' '\n'|sort|uniq|tr '\n' ':'`"
PATH="`echo ${PATH_1%?}`"

## Init Global Env
SPATH=`cd $(dirname $0);pwd`
SOFT_DOC="/opt/soft"
LOG_FILE="/tmp/system_init.log"
SN_TXT="/sn.txt"
PASSWD_FILE="${SPATH}/.sys_user_passwd"
IP_PATH="/etc/sysconfig/network-scripts"

## Alert Content Env
ROOM_TMP="/tmp/.init_room.tmp"
SERVICE_TMP="/tmp/.init_service.tmp"
ALERT_PT="INIT"
[ ! -f "$ROOM_TMP" ] && touch $ROOM_TMP
[ ! -f "$SERVICE_TMP" ] && touch $SERVICE_TMP

## RMDB Url
RMDB_URL_INSIDE="172.0.4.55"
RMDB_INSIDE_PORT="8000"
RMDB_RUL_OUTSIDE="rmdb.test.com"
RMDB_OUTSIDE_PORT="443"

## System config file
SUDO_CONFIG="/etc/sudoers"

## Create Base Dir
create_dirs(){
    ## App
    mkdir -p /opt/{supp_app,web_app,comm_app}
    mkdir -p /logs/{supp_app,web_app,comm_app}

    ## Ops
    mkdir -p /opt/{soft,tasks,ops,custom_monitor}
    mkdir -p /opt/tasks/monitor/ganglia
}

## Add lbss permissions
add_permission(){
    
    chown -R lbss:lbss /opt/{supp_app,web_app,comm_app}
    chown -R lbss:lbss /logs/{supp_app,web_app,comm_app}
}

## Backup config
backup_file(){
    CONF_NAME="$1"
    DATETIME=`date +%F`
    BACKUP_NAME="${CONF_NAME}-${DATETIME}.bak"
    \cp -f ${CONF_NAME} ${BACKUP_NAME}
}

## Del Exist User 
del_user(){
    DEL_USER="$1"
    [ -z "$DEL_USER" ] && echo "Del who?" && exit 1
    if [[ $DEL_USER == "root" ]];then
        echo "Do you want to die!"
        exit 2
    fi
    userdel $DEL_USER
    groupdel $DEL_USER
    rm -rf /home/$DEL_USER
    rm -rf /var/mail/$DEL_USER
    rm -rf /var/spool/cron/$DEL_USER
}

## Get OS Version
get_os_version(){
    OS_VERSION=`lsb_release -r|awk '{print $2}'`
    echo "$OS_VERSION"
}

SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

## Get Local COMM IP
get_ip(){

    COMM_ETH0="$IP_PATH/ifcfg-eth0"
    COMM_ENO1="$IP_PATH/ifcfg-eno1"
    if [[ -f "$COMM_ETH0" ]];then
        COMM_IP=`/sbin/ifconfig eth0|awk '/inet /{print $2}'|egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
    elif [[ -f "$COMM_ENO1" ]];then
        COMM_IP=`/sbin/ifconfig eno1|awk '/inet /{print $2}'`
    elif [[ $SYSTEM_VERSION == 7 ]];then
        COMM_IP=`/sbin/ifconfig em1|awk '/inet /{print $2}'`
    else
        COMM_IP=`/sbin/ifconfig em1|awk '/inet /{print $2}'|awk -F':' '{print $2}'`
    fi

    echo "$COMM_IP"
}

## Get Local OPS IP
get_ops_ip(){

    OPS_ETH1="$IP_PATH/ifcfg-eth1"
    COMM_ENO2="$IP_PATH/ifcfg-eno2"
    if [[ -f "$OPS_ETH1" ]];then
        OPS_IP=`/sbin/ifconfig eth1|awk '/inet /{print $2}'|egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
    elif [[ -f "$COMM_ENO2" ]];then
        OPS_IP=`/sbin/ifconfig eno2|awk '/inet /{print $2}'`
    elif [[ $SYSTEM_VERSION == 7 ]];then
        OPS_IP=`/sbin/ifconfig em2|awk '/inet /{print $2}'`
    else
        OPS_IP=`/sbin/ifconfig em2|awk '/inet /{print $2}'|awk -F':' '{print $2}'`
    fi

    echo "$OPS_IP"
}

get_flag(){
    #if dmidecode -t system|awk '/Product Name:/{print}'|grep -E -i 'Alibaba|OpenStack' > /dev/null;then
    if dmidecode -t system|awk '/Product Name:/{print}'|grep -E -i 'OpenStack' > /dev/null;then
        FG="vm"
    else
        FG="entity"
    fi
    echo "$FG"
}

## Get Local GW
get_gateway(){
    GATEWAY=`ip ro sh|grep default|awk '{print $3}'`
    echo "$GATEWAY"
}

## Get OS Type
get_os_type(){
    OS_TYPE=`lsb_release -i|awk '{print $3}'`
    echo $OS_TYPE
}

## All Log
write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

## Alert
alert(){
    MSG_BODY="$1"
    USERNAME="ntest"
    PASSWORD="ntest"
    INSIDE_IP='172.0.4.54'
    OUTSIDE_DM='owl.test.com'
    PORT="8089"
    if nc -w 2 -z $INSIDE_IP $PORT;then
        ALERT_SMS_URL="http://$INSIDE_IP:$PORT/mail_sms/sms.php"
    else
        ALERT_SMS_URL="http://$OUTSIDE_DM:$PORT/mail_sms/sms.php"
    fi
    # ALERT_SMS_URL="http://172.90.4.54:8889/mail_sms/sms.php"
    # ALERT_SMS_URL="http://owl.transwiseway.com:8889/mail_sms/sms.php"
    ROOM_NAME=`cat $ROOM_TMP`
    SERVICE_NAME=`cat $SERVICE_TMP`

    DATE_TIME=`date +"%F %T"`
    echo "$MSG_BODY"|grep -i "error" > /dev/null
    if [[ $? == 0 ]];then
        MSG_TITLE="服务器初始化失败"
        MONITOR_STATUS="FAILED"
        #MSG_BODY=`echo "$MSG_BODY"|awk -v var='/' --posix '{if($0~/not/){print "<b><span style=color:red>"$0"<"var"span><"var"b><br"var">"}else{print $0"<br"var">"}}'`
    else
        MSG_TITLE="服务器初始化成功"
        MONITOR_STATUS="SUCCESSFUL"
    fi

    if [[ -z "$ROOM_NAME" ]];then
        ROOM_NAME="Null"
    fi

    if [[ -z "$SERVICE_NAME" ]];then
        SERVICE_NAME="Null"
    fi

    ALERT_SMS_CONTENT="<$ROOM_NAME:$ALERT_PT>$SERVICE_NAME::`get_ip`::$ALERT_PT::$MONITOR_STATUS::$MSG_TITLE"

#    for receiver in "${user[@]}"
    cd $SPATH
    for receiver in `cat $SPATH/accounts.cfg|grep -v "^#"`
    do
        curl -d  "notify_receiver=$receiver&notify_title=${ALERT_SMS_CONTENT}&notify_body=${ALERT_SMS_CONTENT}&user_name=${USERNAME}&user_passwd=${PASSWORD}" $ALERT_SMS_URL
        
    done
}

## Check Result 0 or 1
check_result(){
    RESULT_VAL="$?"
    VELUE="$1"
    if [[ $RESULT_VAL != 0 ]];then
        write_log "[ Error ] $VELUE is failed."
        alert "[ Error ] $VELUE is failed."
        exit 2
    else
        write_log "[ Ok ] $VELUE is successful."
    fi
}

## Check User File
#check_user_pwd_file(){
#    if [[ -s "$PASSWD_FILE" ]];then
#        write_log "[ Ok ]$PASSWD_FILE is exist"
#    else
#        write_log "[ Error ]$PASSWD_FILE is not exist"
#        exit 2
#    fi
#}

## Download Software Package
down_url(){
    #URL_IPS=(192.168.111.111 192.168.112.151)
    URL_IP="192.168.12.110"
    URL_OUT="113.14.33.5"
    PORT_OUT="8000"
    DOWN_URL=""
    DOWN_URL_ARG="download_center/software"

    nc -w 2 -z $URL_IP 80 > /dev/null 2>&1
    if [[ $? == 0 ]];then
        DOWN_URL="http://$URL_IP/$DOWN_URL_ARG"
        write_log "Get download URL:http://$URL_IP/$DOWN_URL_ARG"
    fi

    if [[ -z "$DOWN_URL" ]];then
        nc -w 1 -z $URL_OUT $PORT_OUT > /dev/null 2>&1
        check_result "Get download URL:http://$URL_OUT:$PORT_OUT/$DOWN_URL_ARG"
        DOWN_URL="http://$URL_OUT:$PORT_OUT/$DOWN_URL_ARG"
    fi

    echo "$DOWN_URL"
}

## Install Custom rpm PKG
rpm_install(){
    RPM_NAME="$1"
    RPM_PACK="$2"
    rpm -qa|grep "$RPM_NAME" > /dev/null
    if [[ $? == 0 ]];then
        write_log "[ Ok ] ${RPM_NAME} already installed"
    else
        rpm -ivh $RPM_PACK
        check_result "$RPM_NAME"
    fi
}

## RMDB Connect status
check_rmdb_url(){

    nc -w 5 -z $RMDB_URL_INSIDE $RMDB_INSIDE_PORT > /dev/null 2>&1
    I="$?"
    nc -w 5 -z $RMDB_RUL_OUTSIDE $RMDB_OUTSIDE_PORT > /dev/null 2>&1
    O="$?"

    if [[ $I == 0 ]];then
        RMDB_URL="http://$RMDB_URL_INSIDE:$RMDB_INSIDE_PORT"
    elif [[ $O == 0 ]];then
        RMDB_URL="https://$RMDB_RUL_OUTSIDE"
    else
        echo "[ Error ]: rmdb connect failed, Exit!"
        write_log "[ Error ]: rmdb connect failed, Exit!"
    fi

}

