#!/bin/bash
# By xielifeng On 2016-6-30

source ./public.sh
SYSTEM_VERSION="`get_os_version|cut -d. -f1`"

## Add static-route
add_static_route(){
    IDC_ROOM="$1"
    IPS="$2"
    STATIC_ROUTE_FILE="/etc/sysconfig/static-routes"

    # if [[ $IDC_ROOM == 'ALIYUN-BJ' || $IDC_ROOM == 'ALIYUN-HD1' ]];then
    #     OPS_IP=`get_ip`
    # else
    #     OPS_IP=`get_ops_ip`
    # fi
    OPS_IP=`get_ops_ip`
    if [[ -z "$OPS_IP" ]];then
        OPS_IP=`get_ip`
    fi

    if [[ ! -f "$STATIC_ROUTE_FILE" ]];then
        touch $STATIC_ROUTE_FILE
    else
        backup_file "$STATIC_ROUTE_FILE"
    fi

    for IP in $IPS
    do
        grep "$IP" $STATIC_ROUTE_FILE > /dev/null
        if [[ $? == 0 ]];then
            write_log "$IP was added to $STATIC_ROUTE_FILE\n`cat $STATIC_ROUTE_FILE`"
        else
            echo "any net $IP gw $OPS_IP" >> $STATIC_ROUTE_FILE
            #add by xuyingwei
            /sbin/route add -net $IP gw $OPS_IP
            check_result "$IDC_ROOM Add Static Route"
        fi
    done
}

rmdb_init(){

    check_rmdb_url

    LOCAL_IP=`get_ip`
    RMDB_API_OPR="api/get_device_info_by_ip"
    RMDB_API_URL="$RMDB_URL/$RMDB_API_OPR"
    GATEWAY_FIRST=$(echo `get_gateway`|awk -F'.' '{print $1}')
    RESOLVE_CONF_FILE="/etc/resolv.conf"
    NETWORK_CFG="/etc/sysconfig/network"
    HOSTS_CFG="/etc/hosts"

    if [[ -z "$LOCAL_IP" ]];then
        write_log "[ Error ] Get local ip is null"
        exit 2
    fi

    RMDB_INFO=`curl -k -s -d "{\"ex_ip\":\"$LOCAL_IP\", \"flag\":\"$(get_flag)\"}" "$RMDB_API_URL"`
    echo "$RMDB_INFO"|grep -w 'Error' > /dev/null 2>&1
    if [[ $? == 0 ]];then
        write_log "[ Error ] Rmdb api result value error"
        exit 2
    fi

    ROOM=`echo "$RMDB_INFO"|tr ',' '\n'|awk -F ':' '/room/{print $2}'|tr -d '"|}'`
    ASSET=`echo "$RMDB_INFO"|tr ',' '\n'|awk -F ':' '/asset/{print $2}'|tr -d '"'`
    SALT_ID=`echo "$RMDB_INFO"|tr ',' '\n'|awk -F ':' '/salt_id/{print $2}'|tr -d '"|}'`
    # CN=`echo "$ASSET"|awk -F "-" '{print $1}'`

    if [[ -z "$ROOM" ]];then
        write_log "[ Error ] Room is null."
        exit 2
    else
        echo "$ROOM" > $ROOM_TMP
    fi

    if [[ -z "$ASSET" ]];then
        write_log "[ Error ] ASSET is null."
        exit 2
    fi
    
    if [[ -z "$SALT_ID" ]];then
        write_log "[ Error ] SALT_ID is null."
        exit 2
    fi

    ## Add Static Route && Add DNS && Salt-Master IP
    case "$ROOM" in
        ALIYUN-*)
            MASTER_IP="172.90.4.82"
            # NETS="172.90.4.0/24 172.100.4.0/24"
            # DNS="nameserver 100.100.2.138\nnameserver 100.100.2.136"
            # if [[ $GATEWAY_FIRST != 172 ]];then
                # add_static_route "$ROOM" "$NETS"
            # fi
            ;;
        VM6-BJ)
            MASTER_IP="172.90.4.82"
            #NETS="172.90.4.0/24 172.100.4.0/24"
            DNS="nameserver 203.196.0.6\nnameserver 203.196.1.6"
            # if [[ $GATEWAY_FIRST != 172 ]];then
                # add_static_route "$ROOM" "$NETS"
            # fi
            ;;
        VGH-BJ)
            MASTER_IP="172.70.4.51"
            # NETS="172.70.4.0/24 172.90.4.0/24 172.100.4.0/24"
            DNS="nameserver 202.106.0.20\nnameserver 202.106.196.115"
            # if [[ $GATEWAY_FIRST != 172 ]];then
                # add_static_route "$ROOM" "$NETS"
            # fi
            ;;
        VNT-BJ|VNT-XA)
            MASTER_IP="192.168.111.112"
            DNS="nameserver 203.196.0.6\nnameserver 203.196.1.6"
            ;;
        VNT-SH)
            MASTER_IP="192.168.111.251"
            DNS="nameserver 202.96.128.86\nnameserver 202.96.128.166"
            ;;
        WS-BJ)
            MASTER_IP="192.168.100.83"
            DNS="nameserver 203.196.0.6\nnameserver 203.196.1.6"
            ;;
        LX-BJ)
            MASTER_IP="192.168.111.251"
            DNS="nameserver 203.196.0.6\nnameserver 203.196.1.6"
            ;;
        DX-GZ)
            MASTER_IP="172.190.2.53"
            # NETS="172.190.2.0/24 172.190.3.0/24 172.90.4.0/24"
            DNS="nameserver 202.96.128.86\nnameserver 202.96.128.166"
            # if [[ $GATEWAY_FIRST != 172 ]];then
                # add_static_route "$ROOM" "$NETS"
            # fi
            ;;
        DX-CQ)
            MASTER_IP="10.105.16.51"
            DNS="nameserver 61.128.128.68"
            ;;
        Office-OpenStack)
            MASTER_IP="192.168.100.83"
            DNS="nameserver 192.168.100.88\nnameserver 192.168.100.147"
            ;;
        *)
            write_log "[ Error] IDC_ROOM:$ROOM"
            exit 2
    esac

    echo -e "$DNS" > $RESOLVE_CONF_FILE
    echo "nameserver 8.8.8.8" >> $RESOLVE_CONF_FILE

    ## Diff :
    IP_LAST=`echo $LOCAL_IP|awk -F '.' '{print $4}'`
    SALT_ID_LAST=`echo $SALT_ID|awk -F "-" '{print $NF}'`
    if [[ $IP_LAST != $SALT_ID_LAST ]];then
        write_log "Local IP[$IP_LAST] and Salt-id[$SALT_ID_LAST] different."
        exit 2
    fi

    ## Set Salt-minion
    SALT_MINI_CONF="/etc/salt/minion"
    if [[ ! -f "$SALT_MINI_CONF" ]];then
        write_log "$SALT_MINI_CONF is not exist."
        exit 2
    fi

    ## Set salt master value
    grep '^master:' $SALT_MINI_CONF > /dev/null
    SALT_MINI_MASTER="$?"
    if [[ $SALT_MINI_MASTER == 0 ]];then
        sed -i "s/master:.*/master: $MASTER_IP/g" $SALT_MINI_CONF
    else
        sed -i "s/#master:.*/master: $MASTER_IP/g" $SALT_MINI_CONF
    fi

    ## Set salt id value
    grep '^id:' $SALT_MINI_CONF > /dev/null
    SALT_MINI_ID="$?"
    if [[ $SALT_MINI_ID == 0 ]];then
        sed -i "s/id:.*/id: $SALT_ID/g" $SALT_MINI_CONF
    else
        sed -i "s/#id:.*/id: $SALT_ID/g" $SALT_MINI_CONF
    fi

    ## Check Salt master
    grep "^master: $MASTER_IP" $SALT_MINI_CONF > /dev/null
    check_result "Set salt master value"

    ## Check Salt id
    grep "^id: $SALT_ID" $SALT_MINI_CONF > /dev/null
    check_result "Set salt id value"

    ## Restart saltstack
    if [[ $SYSTEM_VERSION == 7 ]];then
        systemctl restart salt-minion
        check_result "salt-minion restart\n`systemctl status salt-minion`"
    else
        /etc/init.d/salt-minion restart
        check_result "salt-minion restart"
    fi

    # a=`echo "$SALT_ID"|awk -F - '{print $1}'`
    # b=`echo "$SALT_ID"|awk -F _ '{print $2}'|cut -c 1,2`
    # c=`echo "$SALT_ID"|awk -F - '{print $3}'|cut -c 2`
    # d=`echo "$SALT_ID"|awk -F - '{print $4}'|cut -d _ -f 1`
    # e=`echo "$SALT_ID"|awk -F _ '{print $3}'|cut -c 1-3`
    # f=`echo "$SALT_ID"|awk -F _ '{print $4}'`
    SERVICE_PT_NAME=`echo "$SALT_ID"|awk -F '_' '{print $2}'`
    echo "$SERVICE_PT_NAME" > $SERVICE_TMP
    
    # C_DB=`echo "$SALT_ID"|awk -F _ '{print $3}'|cut -c 1-2`
    # if [ "$C_DB" != "DB" ];then
        # NEW_HOSTNAME="$a-$b$c-$d-$e-$f"
    # else
        # NEW_HOSTNAME="$a-$b$c-$d-$e$f"
    # fi
    NEW_HOSTNAME="$SALT_ID"
    ## Set hostname
    OLD_HOSTNAME=`hostname`
    if [[ $OLD_HOSTNAME == $NEW_HOSTNAME ]];then
        write_log "Hostname was setted `hostname`"
    elif dmidecode -t system|awk '/Product Name/{print}'|grep -i 'OpenStack' > /dev/null;then
        write_log "OpenStack Cloud Server."
    elif [[ $SYSTEM_VERSION == 7 ]];then
        hostnamectl set-hostname $NEW_HOSTNAME
        check_result "hostnamectl set-hostname\n`hostnamectl status`"
    else
        hostname $NEW_HOSTNAME
        check_result "hostname $NEW_HOSTNAME\n`hostname`"
    fi

    ## Set network file
    if [[ $SYSTEM_VERSION != 7 ]];then
        grep "$NEW_HOSTNAME" $NETWORK_CFG > /dev/null
        if [[ $? != 0 ]];then
            backup_file "$NETWORK_CFG"
            sed -i "s/HOSTNAME=.*/HOSTNAME=$NEW_HOSTNAME/g" $NETWORK_CFG
            check_result "Set $NETWORK_CFG add $NEW_HOSTNAME"
        else
            write_log "[ Ok ] $NETWORK_CFG was setted\n`cat $NETWORK_CFG`"
        fi
    fi

    ## Set hosts file
    grep "$NEW_HOSTNAME" $HOSTS_CFG > /dev/null
    if [[ $? != 0 ]];then
        backup_file "$HOSTS_CFG"
        sed -i -e "s/^127.0.0.1.*/127.0.0.1 $NEW_HOSTNAME localhost/g" -e 's/^::1/#&/g' $HOSTS_CFG
        check_result "Set $HOSTS_CFG add $NEW_HOSTNAME"
    else
        write_log "[ Ok ] $HOSTS_CFG was setted\n`cat $HOSTS_CFG`"
    fi
    
    ## Set sn.txt file
    echo "$ASSET" > $SN_TXT
    check_result "echo $ASSET > $SN_TXT`cat $SN_TXT`"
}

rmdb_init
