#!/bin/bash
# The script is used for init CentOS7.x
# By xielifeng On 2016-10-18

SYSCTL_CONFIG="/etc/sysctl.conf"
SELINUX_CONFIG="/etc/selinux/config"
LIMIT_CONFIG="/etc/security/limits.conf"
LANG_CONFIG="/etc/sysconfig/i18n"
LANG_CFG_7="/etc/locale.conf"
SSHD_CONFIG="/etc/ssh/sshd_config"
SUDO_CONFIG="/etc/sudoers"
LOG_FILE="/tmp/check_result.log"
DISABLE_SERVICES="NetworkManager firewalld"
ZONE_CONFIG="/etc/localtime"

SYSCTL_CONF="""
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 0
"""

> $LOG_FILE

## Backup config
backup_file(){
    CONF_NAME="$1"
    DATETIME=`date +%F`
    BACKUP_NAME="${CONF_NAME}-${DATETIME}.bak"
    \cp -f ${CONF_NAME} ${BACKUP_NAME}
}

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
        exit 2
    else
        write_log "[ Ok ] $VELUE is successful."
    fi
}

disable_service(){
    echo "Disable $DISABLE_SERVICES"
    systemctl stop $DISABLE_SERVICES
    systemctl disable $DISABLE_SERVICES
}

disable_selinux(){
    backup_file "$SELINUX_CONFIG"
    write_log "Backup $SELINUX_CONFIG\n`ls ${SELINUX_CONFIG}*`"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' $SELINUX_CONFIG
    check_result "Disable selinux"
}

disable_ssh_ipv6(){
    SSH_IPV4="ListenAddress 0.0.0.0"
    grep "^$SSH_IPV4" $SSHD_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "SSH ipv6 was disabled"
    else
        sed -i "s/#$SSH_IPV4/$SSH_IPV4/g" $SSHD_CONFIG
        check_result "SSH disable IPV6"
    fi
}

set_sysctl(){
    ## Set Kernel Parameters
    grep '^net.ipv6.conf.all.disable_ipv6 = 1' $SYSCTL_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "$SYSCTL_CONFIG was setted"
    else
        echo "" >> $SYSCTL_CONFIG
        echo "## By OPS On `date +%F`" >> $SYSCTL_CONFIG
        echo  "$SYSCTL_CONF" >> $SYSCTL_CONFIG
        check_result "Set system parameters in $SYSCTL_CONFIG"
    fi
}

set_system(){
    # ----- For CentOS 7.x
    ## Language
    backup_file "$LANG_CFG_7"
    sed -i 's/^LANG=.*/LANG="en_US.UTF-8"/' $LANG_CFG_7
    check_result "Modify $LANG_CFG_7"
 
    ## Set Boot runlevel to 3
    systemctl set-default multi-user.target > /dev/null
    check_result "systemctl set-default multi-user.target"
 
    ## Zone
    timedatectl set-timezone Asia/Shanghai
    check_result "Set TimeZone"
}

set_cpu_used(){
    ## Limit
    grep "* soft nofile 655350" $LIMIT_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "$LIMIT_CONFIG was setted\n`tail -n 10 $LIMIT_CONFIG`"
    else
        backup_file "$LIMIT_CONFIG"
        echo """* soft nofile 655350
* hard nofile 655350
* soft core unlimited
* hard core unlimited
""" >> $LIMIT_CONFIG
        check_result "Setting all user 'soft & hard' limit"
    fi
}

# ---- main:
disable_service
disable_selinux
disable_ssh_ipv6
set_sysctl
set_system
set_cpu_used
