#!/bin/bash

SPATH=`cd $(dirname $0);pwd`
C_GREEN_S="\033[32;49;1m"
C_GREEN_E="\033[39;49;0m"
C_RED_S="\033[32;31;1m"
C_RED_E="\033[39;31;0m"
MY_SELF_GIT="xielifeng"
NOW_TIME=`date +"%F %T"`

FILE=$1

red_echo(){
    echo -e "\033[32;31;1m$1\033[39;31;0m"
}

green_echo(){
    echo -e "\033[32;49;1m$1\033[39;49;0m"
}

print_usage(){
    green_echo "Usage: $0 $SPATH/saltstack/nagios/libexec/check_xxx"
}

[ $# != 1 ] && red_echo "请给定正确的参数" && print_usage && exit 1
[ ! -f $FILE ] && red_echo "$FILE is not exist." && exit 1

FILE_NAME=`basename $FILE`
FILE_DIR=`dirname $FILE`
cd $FILE_DIR

red_echo "--------------切换到pro，进行pull"
sleep 1
git checkout pro
git pull

red_echo "--------------切换到自己的分支"
git checkout $MY_SELF_GIT

green_echo "--------------添加文件到自己的分支"
git add $FILE_NAME
git commit $FILE_NAME -m "commit $FILE_NAME by $MY_SELF_GIT on $NOW_TIME"

[ $? != 0 ] && red_echo "commit $FILE_NAME by $MY_SELF_GIT Failed." && exit 1

red_echo "--------------切换到pro，进行pull"
sleep 1
git checkout pro
git pull

red_echo "--------------切换到自己的分支,合并pro"
git checkout $MY_SELF_GIT
git merge pro -m "$MY_SELF_GIT merge to pro on $NOW_TIME"
[ $? != 0 ] && red_echo "$MY_SELF_GIT merge to pro Failed." && exit 1

red_echo "--------------推送自己的分支到远程仓库"
git push origin ${MY_SELF_GIT}:${MY_SELF_GIT}

[ $? != 0 ] && red_echo "推送自己的分支到远程仓库Failed." && exit 1 

green_echo "--------------Success."
echo ""
green_echo "请到git服务器192.168.100.83:/opt/tasks/git执行git_pull.sh脚本，再到本地pro分支执行'git pull'"
exit 0
