#!/bin/bash
# The script is used for Install Monitor-Client Software(Zabbix,Ganglia,Nagios)
# By xielifeng On 2016-06-28

source ./public.sh
DWON_URL=`down_url`
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

install_zabbix(){

    ## Zabbix Env
    ZABBIX_NAME="zabbix"
    ZABBIX_VERSION="2.2.3"
    ZABBIX_PKG="${ZABBIX_NAME}-${ZABBIX_VERSION}"
    ZABBIX_TAR="${ZABBIX_PKG}.tar.gz"
    ZABBIX_CONF_PKG="zabbix_agentd_conf_d.tar.gz"
    ZABBIX_SH_PKG="zabbix_script.tar.gz"
    ZABBIX_INSTALL_DIR="/opt/ops/$ZABBIX_NAME"
    ZABBIX_ETC_DIR="$ZABBIX_INSTALL_DIR/etc"
    ZABBIX_AGENT_SH="/etc/init.d/zabbix_agentd"
    ZAB_CMD_FILE="/opt/ops/zabbix/sbin/zabbix_agentd"
    ZAB_USER_NAME="zabbix"

    ## Install Zabbix
    write_log "Begin install zabbix ..."

    id $ZAB_USER_NAME > /dev/null
    ZAB_ID_ARG="$?"

    if [[ -f "$ZABBIX_AGENT_SH" && -f "$ZAB_CMD_FILE" && $ZAB_ID_ARG == 0 ]];then
        write_log "Zabbix was installed"
        $ZABBIX_AGENT_SH restart
        check_result "$ZABBIX_AGENT_SH restart\n`ps -ef|grep zabbix|grep -v grep`"
    else
        ## Create zabbix user
        if [[ $ZAB_ID_ARG != 0 ]];then
            groupadd $ZAB_USER_NAME -g 15011 && useradd -u 15011 -g $ZAB_USER_NAME $ZAB_USER_NAME
            check_result "Useradd zabbix user"
        else
            write_log "zabbix user was added"
        fi

        cd $SOFT_DOC
        rm -rf zabbix*
        wget $DWON_URL/$ZABBIX_TAR
        check_result "Download $ZABBIX_TAR"

        wget $DWON_URL/$ZABBIX_CONF_PKG
        check_result "Download $ZABBIX_CONF_PKG"

        wget $DWON_URL/$ZABBIX_SH_PKG
        check_result "Download $ZABBIX_SH_PKG"

        tar -zxf $ZABBIX_TAR
        cd $ZABBIX_PKG
        ./configure --prefix=$ZABBIX_INSTALL_DIR --enable-agent
        check_result "Install Zabbix ./configure"
        make
        check_result "Install Zabbix make"
        make install
        check_result "Install Zabbix make install"

        cd $SOFT_DOC
        tar -zxf $ZABBIX_SH_PKG -C $ZABBIX_INSTALL_DIR
        tar -zxf $ZABBIX_CONF_PKG -C $ZABBIX_ETC_DIR
        chown -R $ZABBIX_NAME:$ZABBIX_NAME $ZABBIX_INSTALL_DIR

        \cp $SOFT_DOC/$ZABBIX_PKG/misc/init.d/fedora/core5/zabbix_agentd /etc/init.d/
        check_result "Add start script to /etc/init.d/"
        sed -i "s|^ZABBIX_BIN=.*|ZABBIX_BIN=$ZAB_CMD_FILE|g" $ZABBIX_AGENT_SH
        check_result "Set $ZABBIX_AGENT_SH\n`awk '/^ZABBIX_BIN=/ {print}' $ZABBIX_AGENT_SH`"
        chmod 755 $ZABBIX_AGENT_SH

        if [[ $SYSTEM_VERSION == 7 ]];then
            systemctl enable zabbix_agentd
            check_result "systemctl enable zabbix_agentd\n`systemctl is-enabled zabbix_agentd`"
        else
            chkconfig --add zabbix_agentd && chkconfig --level 35 zabbix_agentd on
            check_result "'chkconfig --add zabbix_agentd && chkconfig --level 35 zabbix_agentd on'\n`chkconfig --list|grep zabbix_agentd`"
        fi

        $ZABBIX_AGENT_SH start  
        check_result "$ZABBIX_AGENT_SH start\n`ps -ef|grep zabbix|grep -v grep`"
    fi
}

install_gmond(){

    ## Ganglia Env
    GMOND_NAME="ganglia-gmond"
    GMOND_VERSION="3.0.3-1"
    GMOND_REALEASE="rhel4.x86_64"
    GMOND_RPM="${GMOND_NAME}-${GMOND_VERSION}.${GMOND_REALEASE}.rpm"
    GMOND_CONFIG="/etc/gmond.conf"
    GMOND_RUN_CMD="/etc/init.d/gmond"

    if [[ -f "$GMOND_CONFIG" ]];then
        write_log "[ Ok ] Gmond was installed"
        sed -i 's|daemon $GMOND.*|daemon $GMOND --pid-file=/var/run/gmond.pid|g' $GMOND_RUN_CMD
        $GMOND_RUN_CMD restart
        check_result "Restart Gmond\n`ps -ef|grep gmond|grep -v grep`"
    else

        ## Del exist
        cd $SOFT_DOC
        rm -rf ganglia*
        rpm -e $GMOND_NAME

        ## Install
        write_log "Begin install gmond ..."
    
        wget $DWON_URL/$GMOND_RPM
        check_result "Download $GMOND_RPM"
    
        rpm -ivh $GMOND_RPM
        check_result "$GMOND_NAME"
    
        wget $DWON_URL/`basename $GMOND_CONFIG` -C /etc
        check_result "Download `basename $GMOND_CONFIG` to /etc"

        sed -i 's|daemon $GMOND.*|daemon $GMOND --pid-file=/var/run/gmond.pid|g' $GMOND_RUN_CMD
        check_result "Add daemon $GMOND $GMOND_PID_FILE to $GMOND_RUN_CMD"
    
        $GMOND_RUN_CMD start
        $GMOND_RUN_CMD restart
        check_result "$GMOND_RUN_CMD start\n`ps -ef|grep gmond|grep -v grep`"
    fi
    
    
}

install_nagios(){

    ## Nagios Env
    NAG_PLUGINS_NAME="nagios-plugins"
    NAG_PLUGINS_VERSION="1.4.13"
    NAG_PLUGINS_FILE="${NAG_PLUGINS_NAME}-${NAG_PLUGINS_VERSION}"
    NAG_PLUGINS_TAR="${NAG_PLUGINS_FILE}.tar.gz"
    NAG_INSTALL_DIR="/usr/local/nagios"
    NAG_USER_NAME="nagios"
    NRPE_NAME="nrpe-2.8.1"
    NRPE_TAR="${NRPE_NAME}.tar.gz"
    NRPE_RUN_CMD="/etc/init.d/nrpe"

    write_log "Begin install $NAG_USER_NAME ..."

    id $NAG_USER_NAME > /dev/null
    NAG_ID_ARG="$?"
    if [[ -f "$NRPE_RUN_CMD" && -d "$NAG_INSTALL_DIR" && $NAG_ID_ARG == 0 ]];then
        write_log "Nagios was installed"
        $NRPE_RUN_CMD restart
        check_result "$NRPE_RUN_CMD restart\n`ps -ef|grep nrpe|grep -v grep`"
    else
        groupadd $NAG_USER_NAME -g 14001 && useradd -u 14001 -g $NAG_USER_NAME $NAG_USER_NAME
        check_result "Useradd $NAG_USER_NAME"

        cd $SOFT_DOC
        rm -rf nagios*
        rm -rf nrpe*

        ## Install nagios-plugins
        wget $DWON_URL/$NAG_PLUGINS_TAR
        check_result "Download $NAG_PLUGINS_TAR"

        tar -zxf $NAG_PLUGINS_TAR
        cd $NAG_PLUGINS_FILE
        ./configure --prefix=$NAG_INSTALL_DIR
        check_result "Install nagios-plugins ./configure"
        make
        check_result "Install nagios-plugins make"
        make install
        check_result "Install nagios-plugins make install"

        ## Install nrpe
        wget $DWON_URL/$NRPE_TAR
        check_result "Download $NRPE_TAR"

        tar -zxf $NRPE_TAR
        cd $NRPE_NAME
        ./configure --prefix=$NAG_INSTALL_DIR --enable-command-args
        check_result "Install Nrpe ./configure"
        make all
        check_result "Install Nrpe make all"
        make install-plugin
        check_result "Install Nrpe make install-plugin"
        make install-daemon
        check_result "Install Nrpe make install-daemon"
        make install-daemon-config
        check_result "Install Nrpe make install-daemon-config"

        ## Config
        rm -f $NAG_INSTALL_DIR/etc/nrpe.cfg
        wget $DWON_URL/nrpe.cfg -P $NAG_INSTALL_DIR/etc/
        check_result "Download nrpe.cfg to $NAG_INSTALL_DIR/etc/"

        ## OS Up, Run
        rm -f /etc/init.d/nrpe
        wget $DWON_URL/nrpe -P /etc/init.d/
        check_result "Download nrpe to /etc/init.d/"

        chmod 755 $NRPE_RUN_CMD
        if [[ $SYSTEM_VERSION == 7 ]];then
            systemctl enable nrpe
            check_result "systemctl enable nrpe\n`systemctl is-enabled nrpe`"
        else
            chkconfig --add nrpe && chkconfig --level 35 nrpe on
            check_result "chkconfig --add nrpe && chkconfig --level 35 nrpe on"
        fi

        $NRPE_RUN_CMD start
        check_result "$NRPE_RUN_CMD start\n`ps -ef|grep -v grep|grep nrpe`"
    fi
}

#install_zabbix
install_gmond
install_nagios
