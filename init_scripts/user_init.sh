#!/bin/bash
# The script is used for Create user and Modify password.
# By xielifeng On 2016-06-27

source ./public.sh

check_user_pwd_file(){
    if [[ -s "$PASSWD_FILE" ]];then
        write_log "[ Ok ]$PASSWD_FILE is exist"
    else
        write_log "[ Error ]$PASSWD_FILE is not exist"
        exit 2
    fi
}

set_sudo(){
    ## Sudo
    backup_file "$SUDO_CONFIG"

    grep '^Defaults    !requiretty' $SUDO_CONFIG > /dev/null
    SUDO_T1="$?"
    grep '^Defaults    requiretty' $SUDO_CONFIG > /dev/null
    SUDO_T2="$?"
    
    if [[ $SUDO_T1 == 0 ]];then
        write_log "[ Ok ] $SUDO_CONFIG was added 'Defaults !requiretty'\n`grep '^Defaults    !requiretty' $SUDO_CONFIG`"
    elif [[ $SUDO_T2 == 0 ]];then
        sed -i 's/^Defaults    requiretty/Defaults    !requiretty/g' $SUDO_CONFIG
        check_result "$SUDO_CONFIG add 'Defaults !requiretty'\n`grep '^Defaults    !requiretty' $SUDO_CONFIG`"
    else
        echo 'Defaults    !requiretty' >> $SUDO_CONFIG
        check_result "$SUDO_CONFIG add 'Defaults !requiretty'\n`grep '^Defaults    !requiretty' $SUDO_CONFIG`"
    fi

    grep "^zjxl_ops" $SUDO_CONFIG > /dev/null 2>&1
    if [[ $? != 0 ]];then
        echo 'zjxl_ops ALL=(ALL)      NOPASSWD: ALL' >> $SUDO_CONFIG
        check_result "'zjxl_ops ALL=(ALL)      NOPASSWD: ALL' to $SUDO_CONFIG\n`cat $SUDO_CONFIG|grep ^zjxl_ops`"
    else
        write_log "$SUDO_CONFIG was added zjxl_ops\n`cat $SUDO_CONFIG|grep "^zjxl_ops"`"
    fi
}

add_sys_user(){
    ## Add user and modify passwd
    while read LINE
    do
        if [[ -z "$LINE" ]];then
            continue
        fi

        FIRST_NUM=`echo "$LINE"|cut -c 1`
        if [[ $FIRST_NUM == "#" ]];then
            continue
        fi

        USERNAME=`echo "$LINE"|awk '{print $1}'`
        GID=`echo "$LINE"|awk '{print $2}'`
        PASSWD=`echo "$LINE"|awk '{print $3}'`

        if [[ "$GID" == "-" || "$USERNAME" == "root" ]];then
            echo "$PASSWD"|passwd --stdin $USERNAME
            check_result "Modify $USERNAME Password"
            continue
        fi

        #id $USERNAME > /dev/null
        #if [[ $? == 0 ]];then
        #    write_log "$USERNAME is exist."
        #    continue
        #fi

        if [[ "$PASSWD" == "-" ]];then
            groupadd $USERNAME -g $GID
            useradd -u $GID -g $USERNAME $USERNAME
            continue
        fi
    
        if [[ -n "$USERNAME" ]];then
            groupadd $USERNAME -g $GID
            useradd -u $GID -g $USERNAME $USERNAME
            echo "$PASSWD"|passwd --stdin $USERNAME
        fi

        ## Check
        grep "^$USERNAME" /etc/passwd > /dev/null 2>&1
        U_ARG="$?"
        grep "^$USERNAME" /etc/group > /dev/null 2>&1
        G_ARG="$?"
        if [[ $U_ARG == "0" && $G_ARG == "0" ]];then
            write_log "[ Ok ] Add $USERNAME successful."
        else
            write_log "[ Error ] Add $USERNAME failed."
            exit 2
        fi
    
    done < $PASSWD_FILE
}

login_no_passwd(){
    PUB_CA_FILE="${SPATH}/zjxl_ops.pub"

    ## Set user: zjxl_ops
    if [ -f "$PUB_CA_FILE" ];then
        mkdir -p /home/zjxl_ops/.ssh/
        cp -f $PUB_CA_FILE /home/zjxl_ops/.ssh/authorized_keys
        chmod 700 /home/zjxl_ops/.ssh
        chmod 600 /home/zjxl_ops/.ssh/authorized_keys
        chown zjxl_ops:zjxl_ops /home/zjxl_ops/ -R
        check_result "'zjxl_ops' user set no passwd"
    else
        write_log "[ Error ] $PUB_CA_FILE is not exist."
        exit 2
    fi
}

check_user_pwd_file
set_sudo
add_sys_user
login_no_passwd
