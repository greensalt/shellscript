#!/bin/bash
# Update current OpenSSH to openssh-7.5p1
# By L.F.Xie On 2017-06-05

LOG_FILE="/tmp/updateSSH.tmp"
SSH_DIR="/etc/ssh"
BAK_SSH_DIR="/etc/ssh_bak"
SOFT_DIR="/opt/soft"
NEW_SSH="openssh-7.5p1"

SSHD_SERVICE_7="""
[Unit]
Description=OpenSSH server daemon
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target sshd-keygen.service
Wants=sshd-keygen.service

[Service]
EnvironmentFile=/etc/sysconfig/sshd
ExecStart=/usr/sbin/sshd -D $OPTIONS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
"""

## Get OS Version
OS_VERSION=`lsb_release -r|awk '{print $2}'|cut -d. -f1`

## All Log
write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

get_now_sys_info(){
    echo '------- 当前系统信息: --------'
    write_log '------- 当前系统信息: --------'
    sshd -V >> $LOG_FILE

    cat /etc/issue >> $LOG_FILE
    uname -a >> $LOG_FILE
}

update_ssh(){
    COUTENT="------- 升级OpenSSH到7.5p1版本 -------"
    echo "$COUTENT"
    write_log "$COUTENT"

    if [[ -d "$BAK_SSH_DIR" ]];then
        echo "$BAK_SSH_DIR is exist."
        write_log "$BAK_SSH_DIR is exist."
    else
        mv $SSH_DIR $BAK_SSH_DIR
        write_log "mv $SSH_DIR $BAK_SSH_DIR"
    fi

    # yum安装编译安装需要的软件包
    write_log "yum -y install gcc make perl pam pam-devel zlib zlib-devel openssl openssl-devel"
    yum -y install gcc make perl pam pam-devel zlib zlib-devel
    
    # Download openSSH7.5p1
    mkdir -p $SOFT_DIR
    cd $SOFT_DIR
    wget https://mirrors.evowise.com/pub/OpenBSD/OpenSSH/portable/${NEW_SSH}.tar.gz
    if [[ $? == 0 ]];then
        write_log "yum -y remove openssh"
        yum -y remove openssh
    else
        write_log "Download openssh-7.5p1.tar.gz failed."
        exit 1
    fi

    write_log "Install ${NEW_SSH}"
    cd $SOFT_DIR
    tar -zxf ${NEW_SSH}.tar.gz
    cd $NEW_SSH
    ./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib --with-md5-passwords
    make
    make install

    # 测试
    echo "---------- 测试升级是否成功: ----------"
    write_log "---------- 测试升级是否成功: ----------"
    /usr/sbin/sshd -t -f /etc/ssh/sshd_config
    if [[ $? == 0 ]];then
        echo "Update successful."
        write_log "Update successful."
        echo "start SSHD."
    else
        echo "Update failed."
        write_log "Update failed."
    fi

    if [[ $OS_VERSION == 7 ]];then
        echo "SSH_USE_STRONG_RNG=0" > /etc/sysconfig/sshd
        echo "$SSHD_SERVICE_7" > /usr/lib/systemd/system/sshd.service
        systemctl enable sshd
        systemctl start sshd
    else
        cp contrib/redhat/sshd.init /etc/init.d/sshd
        chkconfig --level 2345 sshd on
    fi
}

# --------------: main
## Tmp Contact:
useradd xie
echo 'zjxl2017#6'|passwd --stdin xie
echo 'xie    ALL=(ALL)       ALL' >> /etc/sudoers

yum -y install redhat-lsb-core
get_now_sys_info
update_ssh
get_now_sys_info
