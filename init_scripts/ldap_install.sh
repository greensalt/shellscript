#!/bin/bash
# By Xuyingwei At 2017-02-15

source ./public.sh

install_openldap(){
	yum -y install openldap openldap-clients

	check_result "yum -y install openldap openldap-clients"

	if [[ $SYSTEM_VERSION == 5 ]];then
		yum -y install nss_ldap
		check_result "yum -y install nss_ldap"
	elif [[ $SYSTEM_VERSION == 6 ]];then
		yum -y install nss-pam-ldapd pam_ldap
		check_result "yum -y install nss-pam-ldapd pam_ldap"
	else
		yum -y install nss-pam-ldapd
		check_result "yum -y install nss-pam-ldapd"
	fi
}

install_openldap