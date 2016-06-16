#!/bin/bash
# The script is used to git merge tmp_branch to pro
# By xielifeng On 2016-06-16 (Modify)

TMP_BRANCH_NAME="$1"
C_GREEN_S="\033[32;49;1m"
C_GREEN_E="\033[39;49;0m"
C_RED_S="\033[32;31;1m"
C_RED_E="\033[39;31;0m"
C_YELLOW_S="\033[33m"
C_YELLOW_W="\033[0m"
GIT_TEMP_BRANCH_NAME="/tmp/.git_temp_branch_name"
GIT_TEMP_FILE="/tmp/.temp_git_file"
/bin/true > $GIT_TEMP_BRANCH_NAME

cd /saltstack
BRANCH=`git branch` > /dev/null 2>&1
TMP_BRANCH=`echo "$BRANCH"|grep -v -E "dev|test|ntp|pro|nagios|master|ganglianic|ssh|zabbix"`

EXEC_CHK(){
    if [ $? -eq 0 ];then
        COMMAND="$1"
        echo -e "${C_GREEN_S}OK: $COMMAND 命令成功完成 ${C_GREEN_E}"
        sleep 1
    else
        echo -e "${C_RED_S}ERROR: $COMMAND 命令执行失败 ${C_RED_E}"
        exit 2
    fi
}

BRAN_NAME_CHK(){
    B_NAME=$1
    echo "$TMP_BRANCH"|grep -w "$B_NAME" > /dev/null 2>&1
    if [ $? != 0 ];then
        echo -e "${C_RED_S}ERROR:${C_RED_E} ${C_GREEN_S} ${B_NAME} ${C_GREEN_E} ${C_RED_S}分支在git中不存在...${C_RED_E}"
        exit 1
    fi
}

GIT_MERGE(){
    T_BRANCH="$1"
    BRANCH_DIR="/srv/salt/$T_BRANCH"
    cd /saltstack
    echo -e "====== ${C_RED_S}$T_BRANCH${C_RED_E} ======"
    git checkout ${T_BRANCH} > /dev/null 2>&1
    EXEC_CHK "切换到${T_BRANCH}分支"
    git merge $TMP_BRANCH_NAME > /dev/null 2>&1
    EXEC_CHK "合并$TMP_BRANCH_NAME分支到${T_BRANCH}"

    if [ $T_BRANCH == "pro" ];then
        echo -e "$C_YELLOW_S----请到生产环境git pull----$C_YELLOW_W"
    else
        cd $BRANCH_DIR
        git pull > /dev/null 2>&1
        EXEC_CHK "同步到$BRANCH_DIR"
    fi
}

BRANCH_OPERATION(){
    GIT_REPO="$1"
    cd /saltstack
    CONT=`git log --oneline $TMP_BRANCH_NAME ^${GIT_REPO}|head -1|cut -c 1,3`
    if [ -z "$CONT" ];then
        echo -e "$C_RED_S$TMP_BRANCH_NAME $C_RED_E$C_GREEN_S分支与$C_GREEN_E$C_RED_S ${GIT_REPO} $C_RED_E$C_GREEN_S分支相同,没有要合并的分支$C_GREEN_E"
    else
       #git log --oneline $TMP_BRANCH_NAME ^${GIT_REPO} > $GIT_TEMP_FILE
        GIT_MERGE "$GIT_REPO"

    fi
}

GIT_VIWE(){
    echo -e "$C_RED_S内网分支:$C_RED_E"
    echo -e "$C_GREEN_S         dev $C_GREEN_E"
    echo -e "$C_GREEN_S         test $C_GREEN_E"
    echo -e "$C_RED_S生产分支:$C_RED_E"
    echo -e "$C_GREEN_S         pro $C_GREEN_E"
    echo -e "\n"
    echo -e "${C_RED_S}合并与同步${C_RED_E}${C_GREEN_S}pro$C_GREEN_E"

    for i in test dev pro
    do
        BRANCH_OPERATION "$i"
        sleep 1
    done

}

if [ $# != 1 ];then
    echo  -e "---------- ${C_RED_S}Error:请给出你需要同步合并的分支名称${C_RED_E} ----------"
    echo "Usage: ./$0 \"Branch Name\""
    echo ""
    echo "ex: ./$0 xielifeng"
    echo ""
    exit 1
else
    BRAN_NAME_CHK "$TMP_BRANCH_NAME"
fi

## ------- Main
echo -e "\n"
for i in `echo $TMP_BRANCH`
do
    echo -e "$C_GREEN_S临时分支为:$C_GREEN_E $C_RED_S $i $C_RED_E"
done
echo -e "\n"

GIT_VIWE
