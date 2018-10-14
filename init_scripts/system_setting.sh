#!/bib/bash
# The script is used for Set OS Configure.
# ex: Network,Zone,Cron,SSH,Kernel,Module and so on.
# By xielifeng On 2016-06-27

source ./public.sh

DX_DNS1="202.96.128.86"
DX_DNS2="202.96.128.166"
LT_DNS1="202.106.196.115"
LT_DNS2="202.106.0.20"
ALI_BJ_DNS1="100.100.2.138"
ALI_BJ_DNS2="100.100.2.136"

RESOLV_CONFIG="/etc/resolv.conf"
LIMIT_CONFIG="/etc/security/limits.conf"
SELINUX_CONFIG="/etc/selinux/config"
LANG_CONFIG="/etc/sysconfig/i18n"
LANG_CFG_7="/etc/locale.conf"
INITTAB_CONFIG="/etc/inittab"
RC_LOCAL="/etc/rc.local"

ZONE_CONFIG="/etc/localtime"
CLOCK_CONFIG="/etc/sysconfig/clock"
AREA_ZONE="/usr/share/zoneinfo/Asia/Shanghai"
DATE_ZONE=`echo $AREA_ZONE|awk -F'/' '{print $(NF-1)"/"$NF}'`

NETWORK_CONFIG="/etc/sysconfig/network"
SYSCTL_CONFIG="/etc/sysctl.conf"
KERNEL_CONFIG="$SPATH/sysctl6"
SUDO_CONFIG="/etc/sudoers"

SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

disable_NetworkManager(){

    ps -ef|grep NetworkManager|grep -v grep > /dev/null
    NM=$?

    if [[ $SYSTEM_VERSION == 7 ]];then
        if [[ $NM == 0 ]];then
            systemctl stop NetworkManager
            check_result "systemctl stop NetworkManager"
            systemctl disable NetworkManager
            check_result "systemctl disable NetworkManager"
        else
            write_log "[ Ok ] NetworkManager is not running."
        fi
    else
        if [[ $NM == 0 ]];then
            /etc/init.d/NetworkManager stop
            check_result "Stop NetworkManager"
            chkconfig --level 2345 NetworkManager off
            check_result "Disable NetworkManager"
        else
            write_log "[ Ok ] NetworkManager is not running."
        fi
    fi

    rpm -aq|grep 'NetworkManager' > /dev/null
    NM_PKG="$?"
    if [[ $NM_PKG == 0 ]];then
        yum -y remove NetworkManager
        check_result "yum -y remove NetworkManager"
    fi
}

sys_network(){
    ## DNS
    backup_file "$RESOLV_CONFIG"
    GW=$(echo `get_gateway`|awk -F'.' '{print $1"."$2}')
    
    if [[ $GW == "10.230" || $GW == "172.190" ]];then
        echo "nameserver $DX_DNS1" > $RESOLV_CONFIG
        echo "nameserver $DX_DNS2" >> $RESOLV_CONFIG
    else
        echo "nameserver $LT_DNS1" > $RESOLV_CONFIG
        echo "nameserver $LT_DNS2" >> $RESOLV_CONFIG
    fi
    echo "nameserver 8.8.8.8" >> $RESOLV_CONFIG
    write_log "Setting DNS\n`cat $RESOLV_CONFIG`"

    # ---------------- Network
    backup_file "$NETWORK_CONFIG"
    ## Disable IPV6:
    grep '^NETWORKING_IPV6' $NETWORK_CONFIG > /dev/null 2>&1
    if [[ $? == 0 ]];then
        sed -i 's/^NETWORKING_IPV6=.*/NETWORKING_IPV6=no/g' $NETWORK_CONFIG
    else
        echo "NETWORKING_IPV6=no" >> $NETWORK_CONFIG
    fi
    check_result "Setting 'NETWORKING_IPV6=no' in $NETWORK_CONFIG"

    grep '^IPV6INIT' $NETWORK_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        sed -i 's/IPV6INIT=.*/IPV6INIT=no/g' $NETWORK_CONFIG
    else
        echo "IPV6INIT=no" >> $NETWORK_CONFIG
    fi
    check_result "Set $NETWORK_CONFIG 'IPV6INIT=no'"

    ## Del Default Route
    grep '^NOZEROCONF=yes' $NETWORK_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "[ OK ] 'NOZEROCONF=yes' was setted."
    else
        echo "NOZEROCONF=yes" >> $NETWORK_CONFIG
        check_result "Set $NETWORK_CONFIG 'NOZEROCONF=yes'"
    fi
}

sys_config(){
    # -------------------- System config for CentOS 6.x :

    ## Selinux
    backup_file "$SELINUX_CONFIG"
    write_log "Backup $SELINUX_CONFIG\n`ls ${SELINUX_CONFIG}*`"
    sed -i 's/^SELINUX=.*/SELINUX=disabled/g' $SELINUX_CONFIG
    check_result "Disable selinux"
    
    if [[ $SYSTEM_VERSION == 7 ]];then

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
    else
        ## Language
        backup_file "$LANG_CONFIG"
        sed -i 's/^LANG=.*/LANG="en_US.UTF-8"/' $LANG_CONFIG
        check_result "Setting sys Language:'en_US.UTF-8'"
        
        ## Inittab
        cp -f $INITTAB_CONFIG ${INITTAB_CONFIG}.bak
        sed -i 's/id:5:initdefault:/id:3:initdefault:/g' $INITTAB_CONFIG
        check_result "Setting System run level: 3"
        
        ## Zone
        rm -f $ZONE_CONFIG
        ln -s $AREA_ZONE $ZONE_CONFIG
        sed -i "s%ZONE=.*%ZONE=\"$DATE_ZONE\"%g" $CLOCK_CONFIG
        check_result "Date zone"
    fi

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

lbs soft nproc 65535
lbs hard nproc 65535 """ >> $LIMIT_CONFIG
        check_result "Setting all user 'soft & hard' limit\n`tail -n 10 $LIMIT_CONFIG`"
    fi
}

sys_service(){
    SYS_SERVICES="crond sshd rsyslog irqbalance"

    ## Run these Services when start OS
    if [[ $SYSTEM_VERSION == 7 ]];then
        systemctl enable $SYS_SERVICES 
        check_result "Set system auto run $SYS_SERVICES\n`systemctl is-enabled $SYS_SERVICES`"
    else
        for SERVICE in $SYS_SERVICES
        do
            chkconfig --add $SERVICE && chkconfig --level 35 $SERVICE on
            check_result "Set system auto run $SERVICE\n`chkconfig --list|grep $SERVICE`"
        done
    fi

}

sys_cron(){
    NTP_CRON="/etc/cron.hourly/ntpdate.sh"

    ## Date sync
    rm -f $NTP_CRON
    \cp -f $SPATH/ntpdate.sh $(dirname $NTP_CRON)
    check_result "Cron set ntpdate.sh"
    chmod +x $NTP_CRON
}

disable_ipv6(){

    ## Module Env
    MODULE_CONFIG="/etc/modprobe.d/dist.conf"

    SSH_IPV4="ListenAddress 0.0.0.0"

    ## Net Disable IPV6
    if [[ $SYSTEM_VERSION != 7 ]];then
        grep "alias net-pf-10 off" $MODULE_CONFIG > /dev/null
        if [[ $? == 0 ]];then
            write_log "$MODULE_CONFIG was setted\n`tail -n8 $MODULE_CONFIG`"
        else
            echo -e "\n" >> $MODULE_CONFIG
            echo -e "alias net-pf-10 off" >> $MODULE_CONFIG
            #echo -e "alias ipv6 off" >> $MODULE_CONFIG
            echo -e "options ipv6 disable=1" >> $MODULE_CONFIG
            check_result "Disable IPV6 Module\n`tail -n8 $MODULE_CONFIG`"
        fi
    else
        # 
        grep "^net.ipv6.conf.all.disable_ipv6" $SYSCTL_CONFIG > /dev/null
        if [[ $? == 0 ]];then
            write_log "$SYSCTL_CONFIG was disable ipv6\n`sysctl -p`"
        else
            echo "net.ipv6.conf.all.disable_ipv6 = 1" >> $SYSCTL_CONFIG
            echo "net.ipv6.conf.default.disable_ipv6 = 1" >> $SYSCTL_CONFIG
            check_result "$SYSCTL_CONFIG was disable ipv6"
            sysctl -p
        fi
    fi

}

sys_module(){
    CUSTOM_MOD_DIR="/etc/sysconfig/modules"
    CUSTOM_MOD_FILE="my.modules"
    MODULES="ip_conntrack bridge"

    ## Load module
    for MODU in $MODULES
    do
        /sbin/modprobe $MODU
        #check_result "modprobe $MODU\n`lsmod | grep $MODU`"
        write_log "modprobe $MODU\n`lsmod | grep $MODU`"
    done

    ## Custom Module
    cd $CUSTOM_MOD_DIR
    rm -f $CUSTOM_MOD_FILE
    wget `down_url`/$CUSTOM_MOD_FILE -P $CUSTOM_MOD_DIR 
    check_result "Download $CUSTOM_MOD_FILE to $CUSTOM_MOD_DIR"
    chmod 755 $CUSTOM_MOD_FILE
}

sys_sysctl(){
    ## Set Kernel Parameters
    grep "^net.nf_conntrack_max" $SYSCTL_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "$SYSCTL_CONFIG was setted"
    else
        echo "" >> $SYSCTL_CONFIG
        echo "## By OPS On `date +%F`" >> $SYSCTL_CONFIG
        cat $KERNEL_CONFIG >> $SYSCTL_CONFIG
        check_result "Set system parameters in $SYSCTL_CONFIG"
    fi

    grep "^vm.swappiness" $SYSCTL_CONFIG > /dev/null
    if [[ $? == 0 ]];then
        write_log "[ Ok ] $SYSCTL_CONFIG was added <vm.swappiness>"
    else
        echo "vm.swappiness = 0" >> $SYSCTL_CONFIG
        check_result "Set 'vm.swappiness = 0' in $SYSCTL_CONFIG"
    fi

    grep "^/sbin/modprobe nf_conntrack" $RC_LOCAL > /dev/null
    if [[ $? != 0 ]];then
        echo "" >> $RC_LOCAL
        echo "# By OPS on `date +%F`" >> $RC_LOCAL
        echo "/sbin/modprobe bridge" >> $RC_LOCAL
        echo "/sbin/modprobe nf_conntrack" >> $RC_LOCAL
    fi
    modprobe bridge
    modprobe nf_conntrack
    write_log "`sysctl -p`"
}

sys_sysctl_5(){
    # ------------- For CentOS 5.x -------------
    if  cat /etc/modprobe.conf | grep "alias net-pf-10 off"
    then
        :
    else
        echo -e "\n">>/etc/modprobe.conf
        echo -e "alias net-pf-10 off">>/etc/modprobe.conf
        echo -e "alias ipv6 off">>/etc/modprobe.conf
        echo -e "install ipv6 /bin/true">>/etc/modprobe.conf
    fi

    yum -y install fonts-chinese scim-tables-chinese scim-chinese-standard m2crypto

    /sbin/modprobe ip_conntrack
    if cat /etc/sysctl.conf |grep "ip_conntrack_max"
    then
        :
    else
        echo -e "\n">>/etc/sysctl.conf
        echo -e "net.ipv4.netfilter.ip_conntrack_max = 655360">>/etc/sysctl.conf
        echo -e "net.ipv4.ip_local_port_range = 1024 65535">>/etc/sysctl.conf
    fi

    grep "^/sbin/modprobe ip_conntrack bridge" $RC_LOCAL > /dev/null
    if [[ $? != 0 ]];then
        echo "" >> $RC_LOCAL
        echo "# By OPS on `date +%F`" >> $RC_LOCAL
        echo "/sbin/modprobe ip_conntrack bridge" >> $RC_LOCAL
    fi
    modprobe bridge
    modprobe ip_conntrack
    write_log "`sysctl -p`"

}

disable_NetworkManager
sys_network
sys_config
sys_service
sys_cron
disable_ipv6
sys_module

if [[ $SYSTEM_VERSION == 5 ]];then
    sys_sysctl_5
else
    sys_sysctl
fi
