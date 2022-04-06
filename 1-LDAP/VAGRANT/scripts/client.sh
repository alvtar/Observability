#!/bin/bash

# Client
sudo yum -y install openldap-clients nss-pam-ldapd
sudo authconfig --enableldap --enableldapauth --ldapserver=192.168.80.4 --ldapbasedn="dc=devopsldab,dc=com" --enablemkhomedir --update
getent passwd
