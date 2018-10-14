#!/bin/bash
# The script is used for Install Frigga,and it is base on Ruby.
# By xielifeng On 2015-12-23
# Edit by wayne.xu at 2016-07-01
# Modify By xielifeng On 2016-07-07

source ./public.sh
DWON_URL=`down_url`

RUBY_VERSION="2.1.7"
RUBY_NAME="ruby-$RUBY_VERSION"
RUBY_FILE_TAR="${RUBY_NAME}.tar.gz"
INSTALL_DIR="/opt/ops/Frigga"
HTTP_CONF="conf/frigga.yml"
FRIGGA_CMD="/opt/ops/Frigga/bin/frigga.rb"
FRIGGA_BIN_DIR=`dirname $FRIGGA_CMD`

ADMIN="adminops"
PASSWD="zjxl@11Y30R2015Y"
PORT="5555"

REBOOT_RUN="/etc/rc.local"
ENV_FILE="/etc/profile"
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

install_base_pkg(){
    yum -y install gcc gcc-c++ zlib git openssl openssl-devel
    check_result "Yum install Base_PKG"

    ## Create Dir
    if [[ ! -d "$INSTALL_DIR" ]];then
        mkdir $INSTALL_DIR
        check_result "mkdir $INSTALL_DIR"
    else
        write_log "$INSTALL_DIR was created"
    fi
}
 

install_ruby(){

    RUBY_CMD="/usr/local/bin/ruby"
    GEM_CMD="/usr/local/bin/gem"
 
    write_log "Begin install ruby && gem ..."
    rpm -aq|grep ruby > /dev/null
    if [[ $? == 0 ]];then
        yum -y remove ruby
        check_result "Del default ruby"
    fi
    
    if [[ -L "/bin/ruby" && -L "/bin/gem" ]];then
        write_log "Ruby && Gem was installed"
    else
        # Install ruby && gem
        cd $SOFT_DOC
        [ -f "$RUBY_FILE_TAR" ] && rm -f $RUBY_FILE_TAR
        [ -d "$RUBY_NAME" ] && rm -rf $RUBY_NAME
        mkdir -p $INSTALL_DIR

        # download ruby package from shanxi node
        wget $DWON_URL/$RUBY_FILE_TAR
        check_result "Download $RUBY_FILE_TAR"

        tar -zxf $RUBY_FILE_TAR
        cd $RUBY_NAME
        ./configure
        check_result "Install ruby ./configure"
        make
        check_result "Install ruby make"
        make install
        check_result "Install ruby make install"
        
        [ -f "$RUBY_CMD" ] && ln -s $RUBY_CMD /bin/ruby
        [ -f "$GEM_CMD" ] && ln -s $GEM_CMD /bin/gem
        write_log "Create link `ls -l /bin/ruby`"
        write_log "Create link `ls -l /bin/gem`"

        ## Change gem source
        echo "Del gem source <https://rubygems.org/>"
        gem source -r https://rubygems.org/
        check_result "Del gem source <https://rubygems.org/>"
        echo "Add gem source <https://gems.ruby-china.org/>"
        gem source -a https://gems.ruby-china.org/
        check_result "Add gem source <https://gems.ruby-china.org/>"
        gem source list

        gem install bundle eventmachine
        check_result "gem install bundle eventmachine"

        ln -s /usr/local/bin/bundle /bin/bundle
        ln -s /usr/local/bin/thor /bin/thor
        write_log "Create link `ls -l /bin/bundle`"
        write_log "Create link `ls -l /bin/thor`"
        
    fi
}

install_frigga(){

    write_log "Begin install Frigga ..."
    if [[ -f "$FRIGGA_CMD" && -L "/bin/frigga" && -L "/bin/god" ]];then
        write_log "Frigga was installed"
    else
        # Install Frigga && god
        cd $SOFT_DOC
        wget $DWON_URL/frigga.tar.gz
        check_result "Download frigga.tar.gz"

        tar -zxvf frigga.tar.gz
        \mv frigga/* $INSTALL_DIR/
        cd $INSTALL_DIR
        ln -s $FRIGGA_CMD /bin/frigga
    
        sed -i "s/admin/$ADMIN/;s/123/$PASSWD/;s/9001/$PORT/" $HTTP_CONF
        check_result "Config $HTTP_CONF`cat $HTTP_CONF`"
    
        $RUBY_CMD $INSTALL_DIR/script/run.rb start
        check_result "Start Frigga"
        ln -s /usr/local/bin/god /bin/god

        # Reboot auto run
        RUN_CONTENT="""
## Frigga By OPS On `date +%F`
/bin/ruby /opt/ops/Frigga/script/run.rb start >> /tmp/god_err.log 2>&1
/bin/ruby /opt/ops/Frigga/script/run.rb start >> /tmp/god_err.log 2>&1
"""
        echo "$RUN_CONTENT" >> $REBOOT_RUN
        check_result "Set auto run Frigga `cat $REBOOT_RUN|tail -n 2`"
    fi
}

TOMCAT_START(){
    # Tomcat add config
    # cp setenv.sh /tomcat/bin
    # chown lbs:lbs /tomcat/bin/setenv.sh
    # chmod +x /tomcat/bin/setenv.sh
:
}

if [[ $SYSTEM_VERSION == 6 || $SYSTEM_VERSION == 7 ]];then
    install_base_pkg
    install_ruby
    install_frigga
fi
