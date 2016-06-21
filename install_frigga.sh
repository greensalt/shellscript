#!/bin/bash
# By xielifeng On 2015-12-23

PATH="$PATH:/usr/local/bin"

## ruby2.2版本似乎有bug，会报错，虽然不影响使用，但还是降级使用2.1吧
# RUBY_VERSION="2.2.3"
RUBY_VERSION="2.1.7"
RUBY_NAME="ruby-$RUBY_VERSION"
RUBY_FILE_TAR="$RUBY_NAME.tar.gz"
SOFT_DIR="/opt/soft"
INSTALL_DIR="/opt/ops/Frigga"
HTTP_CONF="conf/frigga.yml"
FRIGGA_CMD="/opt/ops/Frigga/bin/frigga.rb"
FRIGGA_BIN_DIR=`dirname $FRIGGA_CMD`

ADMIN="adminops"
PASSWD="zjxl@11Y30R2015Y"
PORT="5555"

REBOOT_RUN="/etc/rc.local"
ENV_FILE="/etc/profile"

# Install gcc
yum -y install gcc gcc-c++ zlib git openssl openssl-devel

# Install ruby && gem
[ -d "$INSTALL_DIR" ] && rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR
mkdir -p $SOFT_DIR
cd $SOFT_DIR
[ -f "$RUBY_FILE_TAR" ] && rm -f $RUBY_FILE_TAR
[ -d "$RUBY_NAME" ] && rm -rf $RUBY_NAME

wget --no-check-certificate https://cache.ruby-lang.org/pub/ruby/2.1/$RUBY_FILE_TAR
tar -zxf $RUBY_FILE_TAR
cd $RUBY_NAME
./configure
make
make install

ln -s /usr/local/bin/ruby /bin/ruby
ln -s /usr/local/bin/gem /bin/gem

gem source -r https://rubygems.org/ -a https://ruby.taobao.org/
if [ $? != 0 ];then
  echo "====Error:"
  echo "gem source -r https://rubygems.org/ -a https://ruby.taobao.org/   FAIL!"
  exit 1
fi
gem install bundle eventmachine
ln -s /usr/local/bin/bundle /bin/bundle
ln -s /usr/local/bin/thor /bin/thor

# Install Frigga && god
cd $INSTALL_DIR
#which git > /dev/null 2>&1
#[ $? != 0 ] && yum -y install git
git clone https://github.com/xiaomi-sa/frigga.git $INSTALL_DIR

ln -s $FRIGGA_CMD /bin/frigga
mkdir gods
mkdir conf.d
chmod 777 log/

sed -i "s/admin/$ADMIN/;s/123/$PASSWD/;s/9001/$PORT/" $HTTP_CONF
#sed -i "s/^frigga_path/#&/g" $FRIGGA_CMD
#sed -i "s*#{frigga_path}*$FRIGGA_BIN_DIR*g" $FRIGGA_CMD
#sed -i "s*ruby*/bin/ruby*g" $FRIGGA_CMD

ruby ./script/run.rb start
ln -s /usr/local/bin/god /bin/god

# Reboot auto run
RUN_CONTENT="""
## 第一次启动会失败，所以添加两次 Frigga:
/bin/ruby /opt/ops/Frigga/script/run.rb start >> /tmp/god_err.log 2>&1
/bin/ruby /opt/ops/Frigga/script/run.rb start >> /tmp/god_err.log 2>&1
"""
echo "$RUN_CONTENT" >> $REBOOT_RUN

# Tomcat add config
# cp setenv.sh /tomcat/bin
# chown lbs:lbs /tomcat/bin/setenv.sh
# chmod +x /tomcat/bin/setenv.sh