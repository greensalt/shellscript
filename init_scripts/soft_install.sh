#!/bin/bash
# By xielifeng On 2016-06-28

source ./public.sh

install_nginx(){

    ## Nginx Env
    NGX_CMD="/opt/web_app/nginx/sbin/nginx"
    NGX_RELYON_LIB="gcc pcre pcre-devel openssl openssl-devel zlib zlib-devel libevent libevent-devel"
    NGX_USER="nginx"
    NGX_UID="588"
    NGX_NAME="nginx-1.4.1"
    NGX_INSTALL_DIR="/opt/web_app/nginx"
    NGX_PLUGINS="ngx_cache_purge-2.1"

    MONGODB_NGX="mongodb_nginx"
    MONGODB_DIR="/opt/supp_app/mongodb"
    MONGODB_CMD="/opt/supp_app/mongodb/bin/mongod"

    OPENSSL_NAME="openssl"
    OPENSSL_VERSION="1.0.2h"
    OPENSSL_FILE="${OPENSSL_NAME}-${OPENSSL_VERSION}"
    OPENSSL_TAR_PKG="${OPENSSL_FILE}.tar.gz"

    ## Install Nginx
    write_log "Begin install $NGX_NAME ..."
    if [[ -f "$NGX_CMD" ]];then
        write_log "[ Ok ] Nginx was already installed"
    else
        yum -y install $NGX_RELYON_LIB
        if id $NGX_USER;then
            del_user $NGX_USER
        fi

        groupadd $NGX_USER -g 588 && useradd -u 588 -g $NGX_USER $NGX_USER -s /sbin/nologin
        check_result "useradd $NGX_USER"

        cd $SOFT_DOC
        rm -rf ngx_cache_purge*
        rm -rf mongodb_nginx*

        wget `down_url`/${NGX_PLUGINS}.tar.gz
        check_result "Download ${NGX_PLUGINS}.tar.gz"

        wget `down_url`/${MONGODB_NGX}.tar.gz
        check_result "Download ${MONGODB_NGX}.tar.gz"

        wget `down_url`/$OPENSSL_TAR_PKG
        check_result "Download $OPENSSL_TAR_PKG"

        tar -zxf ${NGX_PLUGINS}.tar.gz
        tar -zxf ${MONGODB_NGX}.tar.gz
        tar -zxf $OPENSSL_TAR_PKG

        cd $MONGODB_NGX
        #mv nginx-gridfs /opt/supp_app/nginx-gridfs

        # Install Nginx
        cd $NGX_NAME
        ./configure --prefix=$NGX_INSTALL_DIR --with-http_gzip_static_module --with-http_stub_status_module --user=nginx --group=nginx --with-http_ssl_module --with-http_flv_module --http-log-path=/logs/web_app/nginx_access.log --with-openssl=$SOFT_DOC/$OPENSSL_FILE --with-openssl-opt="enable-tlsext" --add-module=$SOFT_DOC/$NGX_PLUGINS
        check_result "Nginx ./configure"
        make
        check_result "Nginx make"
        make install
        check_result "Nginx make install"
    fi

    ## Install MongDB
    write_log "Begin install MongoDB ..."
    if [[ -f "$MONGODB_CMD" ]];then
        write_log "[ Ok ] MongoDB was already installed"
    else
        cd $SOFT_DOC/$MONGODB_NGX
        rm -rf $MONGODB_DIR
        \cp -rf mongodb-linux-x86_64-2.0.6 $MONGODB_DIR 
        check_result "Install MongoDB"
    fi

    if [[ ! -L "/usr/local/bin/bsondump" ]];then
        ln -s $MONGODB_DIR/bin/* /usr/local/bin/
        check_result "\"ln -s $MONGODB_DIR/bin/* /usr/local/bin/\""
    fi
}

install_tomcat6(){

    ## Tomcat6.0 Env
    TOM6_NAME="apache-tomcat"
    TOM6_VERSION="6.0.29"
    TOM6_FILE="${TOM6_NAME}-$TOM6_VERSION"
    TOM6_TAR_PKG="${TOM6_FILE}.tar.gz"
    TOM6_TARGET_DIR="tomcat_6.0"
    TOM6_INSTALL_DIR="/opt/web_app/$TOM6_TARGET_DIR"
    
    ## Install tomcat6
    write_log "Begin install tomcat6 ..."
    if [[ -d "$TOM6_INSTALL_DIR" ]];then
        rm -rf $TOM6_INSTALL_DIR
    fi

    cd $SOFT_DOC
    rm -rf "${TOM6_FILE}*"

    wget `down_url`/$TOM6_TAR_PKG
    check_result "Download $TOM6_TAR_PKG"
    tar -zxf $TOM6_TAR_PKG
    \mv $TOM6_FILE $TOM6_INSTALL_DIR
    check_result "Install tomcat6"
}

install_tomcat7(){

    ## Tomcat7.0 Env
    TOM7_NAME="apache-tomcat"
    TOM7_VERSION="7.0.30"
    TOM7_FILE="${TOM7_NAME}-${TOM7_VERSION}"
    TOM7_TAR_PKG="${TOM7_FILE}.tar.gz"
    TOM7_TARGET_DIR="tomcat_7.0"
    TOM7_INSTALL_DIR="/opt/web_app/$TOM7_TARGET_DIR"

    ## Install tomcat7
    write_log "Begin install tomcat7 ..."
    if [[ -d "$TOM7_INSTALL_DIR" ]];then
        rm -rf $TOM7_INSTALL_DIR
    fi

    cd $SOFT_DOC
    rm -rf "${TOM7_FILE}*"

    wget `down_url`/$TOM7_TAR_PKG
    check_result "Download $TOM7_TAR_PKG"
    tar -zxf $TOM7_TAR_PKG
    mv $TOM7_FILE $TOM7_INSTALL_DIR
    check_result "Install tomcat7"
}

install_jdk(){

    ## Jdk Env
    JDK_FILE="jdk-6u22-linux-x64.bin"
    JDL_DIR_NAME="jdk1.6.0_22"
    JDK_INSTALL_DIR="/opt/web_app/jdk"

    SYS_PROFILE="/etc/profile"
    SET_JDK_ENV="""
JAVA_HOME=$JDK_INSTALL_DIR
JRE_HOME=\$JAVA_HOME/jre
PATH=\$PATH:\$JAVA_HOME/bin:\$JRE_HOME/bin
CLASSPATH=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar:\$JRE_HOME/lib:
export JAVA_HOME JRE_HOME CLASSPATH PATH
"""

    grep 'JAVA_HOME' $SYS_PROFILE > /dev/null
    JDK_ARG="$?"
    if [[ $JDK_ARG == 0 && -d "$JDK_INSTALL_DIR" ]];then
        write_log "[ Ok ] JDK was installed"
        write_log "Set \"$SYS_PROFILE\" `tail -10 $SYS_PROFILE`"
    else
        ## Install JDK
        write_log "Begin install JDK ..."
        cd $SOFT_DOC
        rm -rf jdk*

        if [[ -f "/usr/bin/java" ]];then
            mv /usr/bin/java /opt/soft
        fi

        wget `down_url`/$JDK_FILE
        check_result "Download $JDK_FILE"
        yes " " | /bin/bash $JDK_FILE
        mv $JDL_DIR_NAME $JDK_INSTALL_DIR
        check_result "Install JDK"

        ## Set Global Env
        write_log "Set JDK environment variable ..."
        grep "JAVA_HOME=/opt/web_app/jdk" $SYS_PROFILE > /dev/null 2>&1
        if [[ $? != 0 ]];then
            echo "## By OPS On `date +%F`" >> $SYS_PROFILE
            echo "$SET_JDK_ENV" >> $SYS_PROFILE
            check_result "JDK Env Set"
        else
            write_log "[ Ok ]JDK Env Already Setted."
        fi
    fi

    add_permission
    add_permission
    check_result "Add lbs user permission `ls -l /logs/ && ls -dl /opt/*_app`"

}

install_nginx
install_tomcat6
install_tomcat7
install_jdk
