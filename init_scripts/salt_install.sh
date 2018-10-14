#!/bin/bash
# By xielifeng On 2016-06-29

source ./public.sh

SYS_VERSION=`get_os_version|cut -d. -f1`
yum_install_salt(){
    SALT_MINI="salt-minion"
    SALT_CERT_DIR="/etc/salt/pki/minion"

    rpm -aq|grep $SALT_MINI > /dev/null
    if [[ $? == 0 ]];then
        write_log "[ Ok ] $SALT_MINI was installed"

        if [[ -d "$SALT_CERT_DIR" ]];then
            rm -rf $SALT_CERT_DIR
            check_result "rm -rf $SALT_CERT_DIR"
        fi

        if [[ $SYS_VERSION == 7 ]];then
            systemctl restart $SALT_MINI
            check_result "systemctl status $SALT_MINI\n`systemctl status $SALT_MINI`"
        else
            /etc/init.d/$SALT_MINI restart
            check_result "/etc/init.d/$SALT_MINI restart"
            write_log "`ps -ef|grep $SALT_MINI|grep -v grep`"
        fi
    else
        yum -y install $SALT_MINI pyOpenSSL
        rpm -aq|grep $SALT_MINI > /dev/null
        check_result "Install $SALT_MINI"
        if [[ $SYS_VERSION == 7 ]];then
            systemctl start $SALT_MINI
            systemctl enable $SALT_MINI
            write_log "systemctl status $SALT_MINI\n`systemctl status $SALT_MINI`"
        else
            /etc/init.d/$SALT_MINI start
            chkconfig --level 2345 $SALT_MINI on
            check_result "Run $SALT_MINI"
            write_log "`ps -ef|grep $SALT_MINI|grep -v grep`"
        fi
    fi
}

install_salt(){


    ## Salt Env
    SALT_RELYON_PKG="python26_salt_6.2.tar.gz"
    SALT_MINION_CMD="/usr/bin/salt-minion"
    SALT_NAME="salt"
    SALT_VERSION="0.17.5"
    SALT_FILE="${SALT_NAME}-${SALT_VERSION}"
    SALT_TAR_PKG="${SALT_FILE}.tar.gz"
    SALT_ROOT_DIR="/etc/salt"
    PYTHON_266="Python-2.6.6"
    PYTHON_266_TAR="${PYTHON_266}.tgz"
    PYTHON_266_CMD="/usr/bin/python2.6"

    [ ! -d $SALT_ROOT_DIR ] && mkdir $SALT_ROOT_DIR

    cd $SOFT_DOC

    ## Install Python 2.6
    if [[ ! -f "$PYTHON_266_CMD" ]];then
        write_log "$PYTHON_266_CMD is not exist. Begin install python2.6 ..."
        rm -rf ${PYTHON_266}*
        check_result "rm -rf ${PYTHON_266}*"

        wget `down_url`/$PYTHON_266_TAR
        check_result "Download $PYTHON_266_TAR"

        tar -zxf $PYTHON_266_TAR
        cd $PYTHON_266
        ./configure --prefix=/usr/local/python2.6 && make && make install
        check_result "Install $PYTHON_266"

        ln -sf /usr/local/python2.6/bin/python2.6 $PYTHON_266_CMD
        check_result "Link: ln -sf /usr/local/python/bin/python2.6 $PYTHON_266_CMD"
    fi
        

    rm -rf python26_salt*

    wget `down_url`/$SALT_RELYON_PKG
    tar -zxf $SALT_RELYON_PKG
    cd centos_install

    rpm_install "libyaml-0.1.5-1.el6" "libyaml-0.1.5-1.el6.x86_64.rpm"
    rpm_install "sshpass-1.05-1.el6" "sshpass-1.05-1.el6.x86_64.rpm"
    rpm_install "openpgm-5.1.118-3.el6" "openpgm-5.1.118-3.el6.x86_64.rpm"
    rpm_install "python-babel-0.9.4-5.1.el6" "python-babel-0.9.4-5.1.el6.noarch.rpm"
    rpm_install "python-msgpack-0.1.13-3.el6" "python-msgpack-0.1.13-3.el6.x86_64.rpm"
    rpm_install "python-crypto-2.0.1-22.el6" "python-crypto-2.0.1-22.el6.x86_64.rpm"
    rpm_install "zeromq3-3.2.4-1.el6" "zeromq3-3.2.4-1.el6.x86_64.rpm"
    rpm_install "python-zmq-2.2.0.1-1.el6" "python-zmq-2.2.0.1-1.el6.x86_64.rpm"
    rpm_install "python-jinja2-2.2.1-1.el6" "python-jinja2-2.2.1-1.el6.x86_64.rpm"
    rpm_install "m2crypto-0.20.2-9.el6" "m2crypto-0.20.2-9.el6.x86_64.rpm"
    rpm_install "MySQL-python-1.2.3-0.3.c1.1.el6" "MySQL-python-1.2.3-0.3.c1.1.el6.x86_64.rpm"
    rpm_install "PyYAML-3.10-3.el6" "PyYAML-3.10-3.el6.x86_64.rpm"

    cd $SOFT_DOC
    if [[ -f "$SALT_MINION_CMD" ]];then
        write_log "[IGNORE] saltstack already install..."
    else
        ## Install Salt-Minion
        rm -rf salt*
        wget `down_url`/$SALT_TAR_PKG
        tar -zxf $SALT_TAR_PKG
        cd $SALT_FILE
        $PYTHON_266_CMD setup.py install
        check_result "$SALT_FILE"
        \cp -f $SOFT_DOC/$SALT_FILE/conf/minion /etc/salt

        ## Sys Up, Run
        wget `down_url`/salt-minion -P /etc/init.d/
        chmod 755 /etc/init.d/salt-minion

        if [[ $SYS_VERSION == 7 ]];then
            systemctl enable salt-minion
            check_result "systemctl enable salt-minion\n`systemctl is-enabled salt-minion`"
        else
            chkconfig --add salt-minion && chkconfig --level 35 salt-minion on
            check_result "Add start system auto run for salt-minion\n`chkconfig --list salt-minion`"
        fi

        /etc/init.d/salt-minion start
        check_result "Start salt-minion\n`/etc/init.d/salt-minion status`"
    fi

    ## Del Master Cmd
    cd /usr/bin
    if [[ -f salt-master && -f salt-key ]];then
        rm -f salt-master salt-cp salt salt-key salt-master salt-run salt-ssh salt-syndic
        check_result "rm -f salt-master salt-cp salt salt-key salt-master salt-run salt-ssh salt-syndic"
    fi
    
}

#if [[ $SYS_VERSION == 7 || $SYS_VERSION == 6 ]];then
    yum_install_salt
#else
#    install_salt
#fi
