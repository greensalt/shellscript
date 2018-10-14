#!/bin/bash
# By L.F.Xie On 2017-12-05

source ./public.sh
OPS_IP=`get_ops_ip`
if [[ -z "$OPS_IP" ]];then
    OPS_IP=`get_ip`
fi
STATIC_ROUTE_FILE="/etc/sysconfig/static-routes"
NETS="172.190.2.0/24 172.190.3.0/24 172.90.4.0/24 172.70.4.0/24 172.100.4.0/24"
> $STATIC_ROUTE_FILE

if dmidecode -t system|awk '/Product Name/{print}'|grep -E 'Ali|Cloud' > /dev/null;then
    write_log "Aliyun Cloud Server."
else
    for NET in $NETS
    do
        if ip ro s|grep "$NET" > /dev/null;then
            write_log "<$NET> was add."
        else
            route add -net $NET gw $OPS_IP
            check_result "route add -net $NET gw $OPS_IP"
        fi
        
        if grep "$NET" $STATIC_ROUTE_FILE > /dev/null;then
            write_log "<$NET> in $STATIC_ROUTE_FILE"
        else
            echo "any net $NET gw $OPS_IP" >> $STATIC_ROUTE_FILE
            write_log "any net $NET gw $OPS_IP >> $STATIC_ROUTE_FILE"
        fi
    done
fi