#!/bin/bash
# The script is used for Install Base Packages
# By xielifeng On 2016-06-27

source ./public.sh
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"
COBBLER_REPO="/etc/yum.repos.d/cobbler-config.repo"
YUM_PID_F="/var/run/yum.pid"
PKG_TMP="/tmp/packages.tmp"
NC_PKG="nc-1.84-24.el6.x86_64.rpm"

## Create App Dir
create_dirs
write_log "Create Base Dir\n`ls /opt`"

#BASE_PACKAGES="""iproute pcre pcre-devel openssl openssl-devel zlib zlib-devel irqbalance python-simplejson ntp libevent libevent-devel openssh-clients openssh dmidecode mysql gmp perl-DBI vim-common vim-enhanced vim-minimal iotop dstat wget make vixie-cron wget lrzsz tree sudo traceroute screen bc lsof sysstat compat-gcc-34 compat-libstdc++-296 control-center gcc gcc-c++ glibc glibc-common glibc-devel libaio libgcc libstdc++ libstdc++-devel libXp make openmotif22 setarch redhat-lsb-core"""

BASE_PACKAGES="""iproute pcre pcre-devel openssl openssl-devel zlib zlib-devel irqbalance python-simplejson ntp libevent libevent-devel openssh-clients openssh dmidecode gmp perl-DBI wget make vixie-cron traceroute bc lsof sysstat compat-gcc-34  gcc gcc-c++ libaio libgcc libstdc++ libstdc++-devel libXp openmotif22 setarch redhat-lsb-core gd gd-devel gdb"""

## Clean Rubbish
[ -f "$COBBLER_REPO" ] && rm -f $COBBLER_REPO

if [ -f "$YUM_PID_F" ];then
    PID=`cat $YUM_PID_F`
    kill -9 $PID
    rm -f $YUM_PID_F
fi

## Install Base Packages
yum -y update $BASE_PACKAGES
check_result "yum update Base-PKG 1"
yum -y install $BASE_PACKAGES
check_result "yum install Base-PKG 2"
yum -y update $BASE_PACKAGES
check_result "yum update Base-PKG 3"

## Install NC Command
write_log "Install NC Command ..."
if [[ $SYSTEM_VERSION == 7 ]];then
    yum -y remove nmap-ncat
    write_log "Del system nc"
    rpm -ivh "$SPATH/$NC_PKG"
    check_result "Install NC command"
else
    which nc > /dev/null
    if [[ $? != 0 ]];then
        yum -y install nc
    fi
fi

