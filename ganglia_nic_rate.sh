#!/bin/bash
# Support CentOS5.x,6.x,7.x
# By xielifeng On 2016-02-15 

SECOND=10
NETWORK=`/sbin/ifconfig|grep -Ev "^ |lo"|awk '{print $1}'|tr -s '\n'|cut -d : -f 1|sort|uniq`

## Get OS Version
get_os_version(){
    OS_VERSION=`$(which lsb_release) -r|awk '{print $2}'|cut -d . -f 1`
    echo "$OS_VERSION"
}

get_net_interface_rate(){
    while :
    do
        for i in $NETWORK
        do
            IP=`/sbin/ifconfig $i|awk '/inet /{print $2}'|awk -F ':' '{print $NF}'`
            if [ -z "$IP" ];then
                continue
            fi
    
            rx_before=`/sbin/ifconfig $i|grep "RX bytes"|awk '{print $2}'|cut -c7-`
            tx_before=`/sbin/ifconfig $i|grep "RX bytes"|awk '{print $6}'|cut -c7-`
            sleep $SECOND
            rx_after=`/sbin/ifconfig $i|grep "RX bytes"|awk '{print $2}'|cut -c7-`
            tx_after=`/sbin/ifconfig $i|grep "RX bytes"|awk '{print $6}'|cut -c7-`
            rx_result=$(echo "scale=1; ( $rx_after - $rx_before ) / $SECOND" | bc -q)
            tx_result=$(echo "scale=1; ( $tx_after - $tx_before ) / $SECOND" | bc -q)
            /usr/bin/gmetric -tuint32 -nnic_rate_rx-"$i" -v"$rx_result" -u"bytes per sec"
            /usr/bin/gmetric -tuint32 -nnic_rate_tx-"$i" -v"$tx_result" -u"bytes per sec"
       done
    done
}

get_net_interface_rate_7(){
    while :
    do
        for i in $NETWORK
        do
            IP=`/sbin/ifconfig $i|awk '/inet /{print $2}'|awk -F ':' '{print $NF}'`
            if [ -z "$IP" ];then
                continue
            fi

            rx_before=`/sbin/ifconfig $i|awk '/RX packets/ {print $5}'`
            tx_before=`/sbin/ifconfig $i|awk '/TX packets/ {print $5}'`
            sleep $SECOND
            rx_after=`/sbin/ifconfig $i|awk '/RX packets/ {print $5}'`
            tx_after=`/sbin/ifconfig $i|awk '/TX packets/ {print $5}'`
            rx_result=$(echo "scale=1; ( $rx_after - $rx_before ) / $SECOND" | bc -q)
            tx_result=$(echo "scale=1; ( $tx_after - $tx_before ) / $SECOND" | bc -q)
            /usr/bin/gmetric -tuint32 -nnic_rate_rx-"$i" -v"$rx_result" -u"bytes per sec"
            /usr/bin/gmetric -tuint32 -nnic_rate_tx-"$i" -v"$tx_result" -u"bytes per sec"
       done
    done
}

# --------- main ---------
if [[ `get_os_version` == 7 ]];then
    get_net_interface_rate_7
else
    get_net_interface_rate
fi
