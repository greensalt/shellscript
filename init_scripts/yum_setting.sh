#!/bin/bash
# The script is used for Set Yum Repo
# By xielifeng On 2016-07-04

source ./public.sh
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

set_yum_cfg(){
    YUM_CFG="/etc/yum.conf"
    YUM_CFG_EXCLUDE="exclude=kernel* *i686* *i386*"

    backup_file "$YUM_CFG"
    write_log "Backup $YUM_CFG\n`ls ${YUM_CFG}*`"
    grep '^exclude' $YUM_CFG > /dev/null
    if [[ $? == 0 ]];then
        sed -i "s/exclude=.*/$YUM_CFG_EXCLUDE/g" $YUM_CFG
    else
        sed -i "N;2a$YUM_CFG_EXCLUDE" $YUM_CFG
    fi
    
}

## Set Yum Repo
set_zjxl_repo(){

    YUM_REPO_DIR="/etc/yum.repos.d"
    REPO_FILE="ZJXL_Base.repo"

    cd $YUM_REPO_DIR


    [ ! -d bak ] && mkdir bak
    ls|grep -v -E 'bak|Base'|xargs -i mv {} bak/
    check_result "Backup yum-repo\n`ls $YUM_REPO_DIR`"

    if [[ ! -f "$SPATH/$REPO_FILE" ]];then
        write_log "[ Error ]$REPO_FILE is not exist"
        exit 2
    else
        \cp -f $SPATH/$REPO_FILE $YUM_REPO_DIR
    fi

    yum clean all
    #yum makecache
    check_result "Set yum repo"
}

echo 'nameserver 202.106.0.20' >> /etc/resolv.conf
#if [[ $SYSTEM_VERSION == 7 ]];then
#    set_yum_cfg
#fi
set_zjxl_repo
