#!/bin/bash

CREATEINIT(){
    tmpGuest=${tmpGuest}
    mkdir -p ${tmpGuest}
}


IFCFG(){
    ##生成虚拟机网卡配置文件
    tmpGuest=$1
    guestSN=$2
    guestIPADDR=$3
    guestNETMASK=$4
    guestGATEWAY=$5
    ifcfgConf="${tmpGuest}ifcfg-eth0"

    /bin/cp ${G_TEMPLATE}ifcfg-eth0 ${ifcfgConf}
    sed -i "/^IPADDR/c IPADDR=${guestIPADDR}" ${ifcfgConf}
    sed -i "/^NETMASK/c NETMASK=${guestNETMASK}" ${ifcfgConf}
    sed -i "/^GATEWAY/c GATEWAY=${guestGATEWAY}" ${ifcfgConf}

}

NTP(){
    ##配置NTP
    tmpGuest=$1
    cp ${G_TEMPLATE}adjtime ${tmpGuest}adjtime
    cp ${G_TEMPLATE}ntp.conf ${tmpGuest}ntp.conf
}
 
DNS(){
    #生成resolv.conf配置文件
    tmpGuest=$1
    guestDNS1=$2
    guestDNS2=$3
    resolvConf="${tmpGuest}resolv.conf"    

    /bin/cp ${G_TEMPLATE}resolv.conf ${resolvConf}
    sed -i "/DNS1/c nameserver ${guestDNS1}" ${resolvConf}
    sed -i "/DNS2/c nameserver ${guestDNS2}" ${resolvConf}
}   

HOSTSALLOW(){
    #更新虚拟及hosts.allow配置文件
    tmpGuest=$1
    cp ${G_TEMPLATE}hosts.allow ${tmpGuest}hosts.allow
}

GRUB(){
    #更新grub配置
    tmpGuest=$1
    cp ${G_TEMPLATE}grub ${tmpGuest}grub
}

VMINIT(){
    #添加初始化脚本
    tmpGuest=$1
    cp ${G_TEMPLATE}vm_step1.sh ${tmpGuest}vm_step1.sh
}

RCINIT(){
    #编辑RC.LOCAL文件
    tmpGuest=$1
    cp ${G_TEMPLATE}rc.local ${tmpGuest}rc.local
}



GETIMG(){
    #下载img镜像到本地
    tmpGuest=$1
    guestSN=$2
    guestOSIMG=$3
    getUrl=`grep ${guestOSIMG} ${G_CONFIG}|awk -F "=" '{print $2}'`

    if [ -n "${getUrl}" ]
    then
        wget --limit-rate=${G_LIMIT} ${getUrl} -O ${tmpGuest}${guestSN}
    else
        echo "未获取到变量"
        exit 1
    fi    
}


IMGINIT(){
    #初始化镜像文件
    tmpGuest=$1
    guestSN=$2
    guestOSIMG=${tmpGuest}${guestSN}
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}ifcfg-eth0 /etc/sysconfig/network-scripts/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}adjtime /etc/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}hosts.allow /etc/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}ntp.conf /etc/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}resolv.conf /etc/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}grub /etc/default/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}vm_step1.sh /tmp/
    virt-copy-in -a ${guestOSIMG} ${tmpGuest}rc.local /etc/rc.d/
}

## 录入CMDB, add by Lion, on 2020-05-13
to_cmdb(){
    cmdb_url="http://10.6.8.8:8000/cmdb/devices/saveCloud"
    token="a1e9d9cb1b0f86e5658"
    vmSN="$1"
    parentSn="$2"
    ip="$3"
    # SYS-KVM-C-03-04
    sets="$4"
    # OS-SYSOS-C-72-64
    os="$5"

    curl -X POST $cmdb_url -d token="$token" -d 'devices=[{sn:"'${vmSN}'",parentSn:"'${parentSn}'", ip:"'${ip}'",  set:"'${sets}'", os:"'${os}'", cloudType:"syscloud"}]'
    
}


##执行部分
vmInfoFile=$1
#读取虚拟机创建表信息
if [ ! -n "${vmInfoFile}" ]
then
    echo "./createVM.sh vmlist"
    exit 1
fi

if [ ! -e ${vmInfoFile} ]
then
    echo "虚拟机创建列表文件不存在!"
    exit 1
fi

 # yum -y --disablerepo=\* --enablerepo=base-7.3.1611 install libguestfs-tools
rpm -aq|grep libguestfs-tools > /dev/null
if [[ $? != 0 ]];then
    yum -y install libguestfs-tools
fi

source ../conf/path.sh
hostMem=`free -m|grep Mem|awk '{print $2}'`
hostCpu=`cat /proc/cpuinfo |grep processor|wc -l`
hostMem=`expr ${hostMem} / 2`
hostCpu=`expr ${hostCpu} / 2`

cat ${vmInfoFile}|grep -v '^#'|while read vmInfo
do
    guestSN=`echo ${vmInfo}|awk '{print $1}'`
    guestIPADDR=`echo ${vmInfo}|awk '{print $2}'`
    guestNETMASK=`echo ${vmInfo}|awk '{print $3}'`
    guestGATEWAY=`echo ${vmInfo}|awk '{print $4}'`
    guestVNCPORT=`echo ${vmInfo}|awk '{print $5}'`
    guestVNCPASS=`echo ${vmInfo}|awk '{print $6}'`
    guestCPU=`echo ${vmInfo}|awk '{print $7}'`
    guestMEM=`echo ${vmInfo}|awk '{print $8}'`
    guestTEMPLATE=`echo ${vmInfo}|awk '{print $10}'`
    guestOSIMG=`echo ${vmInfo}|awk '{print $11}'`
    guestDNS1=`echo ${vmInfo}|awk '{print $12}'`
    guestDNS2=`echo ${vmInfo}|awk '{print $13}'`
    hostIPADDR=`echo ${vmInfo}|awk '{print $9}'`
    tmpGuest="${G_TMP}${guestSN}_${G_DATE}/"       

    

    CREATEINIT ${tmpGuest}
    IFCFG ${tmpGuest} ${guestSN} ${guestIPADDR} ${guestNETMASK} ${guestGATEWAY}
    NTP ${tmpGuest}
    DNS ${tmpGuest} ${guestDNS1} ${guestDNS2}
    HOSTSALLOW ${tmpGuest}
    GRUB ${tmpGuest}
    VMINIT ${tmpGuest}
    RCINIT ${tmpGuest}
    GETIMG ${tmpGuest} ${guestSN} ${guestOSIMG}
    IMGINIT ${tmpGuest} ${guestSN}
    mv ${tmpGuest}${guestSN} ${G_VMDIR}
    virt-install --name ${guestSN} --uuid ${guestSN} --memory=${guestMEM} --arch=x86_64 --vcpus=${guestCPU} --check-cpu --os-type=linux --os-variant='rhel7.0' --boot hd --disk path=${G_VMDIR}${guestSN}  --network bridge=br0 --noautoconsole --graphics vnc,password=${guestVNCPASS},listen=0.0.0.0,port=${guestVNCPORT}

done
