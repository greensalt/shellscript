#!/bin/bash
# The script is used for Get HOST Info
# By xielifeng On 2016-07-04

## RMDB Info
RMDB_URL_INSIDE="172.0.4.5"
RMDB_INSIDE_PORT="8080"
RMDB_RUL_OUTSIDE="rmdb.trans.com"
RMDB_OUTSIDE_PORT="8443"
RMDB_API_OPR="api/update_server_device_info"

LOG_FILE="/tmp/.update_devInfo_to_rmdb.log"

## RMDB Connect status
check_rmdb_url(){
    nc -w 5 -z $RMDB_URL_INSIDE $RMDB_INSIDE_PORT > /dev/null 2>&1
    I="$?"
    nc -w 5 -z $RMDB_RUL_OUTSIDE $RMDB_OUTSIDE_PORT > /dev/null 2>&1
    O="$?"
    if [[ $I == 0 ]];then
        RMDB_URL="http://$RMDB_URL_INSIDE:$RMDB_INSIDE_PORT"
    elif [[ $O == 0 ]];then
        RMDB_URL="https://$RMDB_RUL_OUTSIDE"
    else
        alert "[ Error ]: rmdb connect failed, Exit!"
        exit 2
    fi
}

## All Log
write_log(){
    CONTENT="$*"
    NOW_TIME=`date +"%F %T"`
    echo "" >> $LOG_FILE
    echo -e "$NOW_TIME $CONTENT" >> $LOG_FILE
}

get_factory(){
    FACTORY="Null"
    #VM=`/usr/sbin/dmidecode |grep -i product|head -1|awk -F ":" '{print $2}'|cut -d " " -f 2|tr '[a-z]' '[A-Z]'`
    VM=`dmidecode -t system|grep -i product|awk '{print $3}'|tr '[a-z]' '[A-Z]'`
    if [[ "$VM" == "VMWARE" || "$VM" == "OPENSTACK" || "$VM" == "ALIBABA" ]];then
        FACTORY="$VM"
    else
        FACTORY=`/usr/sbin/dmidecode |grep -i Vendor|awk '{print $2}'|tr '[a-z]' '[A-Z]'`
    fi

    echo "$FACTORY"
}

get_model(){
    case `get_factory` in
        IBM)
            HOST_MODEL=`/usr/sbin/dmidecode |grep -i product|awk 'NR==1{print $5,$6}'|tr -d " "`
            ;;
        HP)
            HOST_MODEL=`/usr/sbin/dmidecode |grep -i product|awk -F ":" 'NR==1{print $2}'|tr -d " "`
            ;;
        DELL|ALIBABA)
            HOST_MODEL=`/usr/sbin/dmidecode -t system|grep "Product Name"|awk '{print $NF}'`
            ;;
        VMWARE|OPENSTACK)
            HOST_MODEL="`get_factory`"
            ;;
        *)
            HOST_MODEL="Null"
            ;;
    esac

    echo "$HOST_MODEL"
}

get_cpu_type(){
    if [ `get_model` == "R910" -o `get_model` == "ProLiantDL580G7" ];then
        CPU_TYPE=`cat /proc/cpuinfo|grep "model name"|awk -F ":" 'NR==1{print $2}'|awk '{print $4,$5}'|tr -d " "`
    elif [ `get_model` == "OPENSTACK" ];then
        CPU_TYPE="Null"
    else
        CPU_TYPE=`cat /proc/cpuinfo|grep "model name"|awk -F ":" 'NR==1{print $2}'|awk '{print $4}'`
    fi
    echo $CPU_TYPE
}

get_physical_cpu_num(){
    if [[ `get_factory` == "OPENSTACK" ]];then
        PHY_CPU_NUM="1"
    else
        PHY_CPU_NUM=`cat /proc/cpuinfo |grep "physical id"|sort|uniq|wc -l`
    fi
    echo "$PHY_CPU_NUM"
}

get_logic_cpu_num(){
    LOGIC_CPU_NUM=`cat /proc/cpuinfo |grep "processor"|wc -l`
    echo "$LOGIC_CPU_NUM"
}

get_cpu_core_num(){
    CPU_CORE_NUM=`cat /proc/cpuinfo |grep "cores"|uniq|awk '{print $4}'`
    echo "$CPU_CORE_NUM"
}

get_memory_num(){
    #MEM_NUM=`dmidecode -t memory|grep Size|grep -v "No Module Installed"|wc -l`
    MEM_NUM=`dmidecode -t memory|grep Size|grep -v -E "Not Installed|No Module Installed|Maximum|Enabled|Installed"|wc -l`
    echo "$MEM_NUM"
}

#get_memory_size(){
#    MEM_TOTAL=`dmidecode -t memory|grep Size|grep -v "No Module Installed"|awk '{sum=sum+$2}END{print sum/1024}'`
#    echo "${MEM_TOTAL}G"
#}

get_memory_size(){
    #MEM_TOTAL=`dmidecode -t memory|grep Size|grep -v "No Module Installed"|awk '{print $2/1024}'|uniq`
    MEM_TOTAL=`dmidecode -t memory|grep Size|grep -v -E "Not Installed|No Module Installed|Maximum|Enabled|Installed"|awk '{print $2/1024}'|uniq`
    echo "${MEM_TOTAL}G"
}

get_memory_type(){
    MEM_TYPE=`dmidecode -t memory|grep DDR|head -1|awk '{print $2}'`
    echo "$MEM_TYPE"
}

get_disk_size(){
    DISK_TOTAL_SIZE=`df -k|grep -E -v 'tmpfs'|awk 'NR!=1{sum=sum+$2}END{print sum/(1024**2)}'|awk -F'.' '{print $1}'`
    echo "${DISK_TOTAL_SIZE}"
}

get_ip_pool(){
    IP_POOL=`/sbin/ip a | grep 'inet ' | grep -v '127.0.0.1' | awk -F '[ |/]' 'BEGIN{ORS=","}{print $6}'`
    echo "$IP_POOL"
}

get_ssh_port(){
    SSH_PORT=`ss -lntp|grep sshd|grep -vE ":::|127.0.0.1"|awk '{print $(NF-2)}'|cut -d':' -f2`
    echo "$SSH_PORT"
}

get_power_num(){
    echo "2"
}

get_serial_num(){
    SERIAL_NUM=`dmidecode -t system|grep "Serial Number"|awk '{print $3}'`
    [ -z "$SERIAL_NUM" ] && SERIAL_NUM="Null"
    echo "$SERIAL_NUM"
}

post_to_rmdb(){
    curl -k -d "{\"factory\":\"`get_factory`\",\"ex_model\":\"`get_model`\",\"os\":\"`get_os_type` `get_os_version`\",\"ex_cpu_type\":\"`get_cpu_type`\",\"cpu_num\":\"`get_logic_cpu_num`\",\"mem_capacity\":\"`get_memory_size`\",\"mem_num\":\"`get_memory_num`\",\"mem_type\":\"`get_memory_type`\",\"spareDisk\":\"`get_disk_size`\",\"ex_ip\":\"`get_ip`\",\"ip_pool\":\"`get_ip_pool`\",\"ssh_port\":\"`get_ssh_port`\",\"power_num\":\"`get_power_num`\",\"service_num\":\"`get_serial_num`\"}" "$RMDB_API_URL" >> $LOG_FILE
    write_log "System info update to RMDB"
}

check_rmdb_url
RMDB_API_URL="$RMDB_URL/$RMDB_API_OPR"
post_to_rmdb

