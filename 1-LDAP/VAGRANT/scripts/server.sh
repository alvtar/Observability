#!/bin/bash

# Update yum database
sudo yum update -y

# Install OpenLDAP Server 
sudo yum install openldap openldap-servers openldap-clients -y
sudo systemctl start slapd
sudo systemctl enable slapd
sudo systemctl status slapd

# Set passwords
ADMIN_PASSWD=$(cat ldifs/admin_passwd)
USER_PASSWD=$(cat ldifs/user_passwd)
PASSWORD=$(slappasswd -s ${ADMIN_PASSWD})
PASSWORD2=$(slappasswd -s ${USER_PASSWD})

# Create ldaprootpasswd.ldif
sed -i "s/PASS/${PASSWORD}/g" ldifs/ldaprootpasswd.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ldifs/ldaprootpasswd.ldif

# LDAP Database
sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

# Domain config
sed -i "s/PASS/${PASSWORD}/g" ldifs/ldapdomain.ldif
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldifs/ldapdomain.ldif

# Add baseldapdomain.ldif
sudo ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w ${ADMIN_PASSWD} -f ldifs/baseldapdomain.ldif

# Add group
sudo ldapadd -x -D "cn=Manager,dc=devopsldab,dc=com" -w ${ADMIN_PASSWD} -f ldifs/ldapgroup.ldif

# Add user
sed -i "s/USER_PASSWD/${PASSWORD2}/g" ldifs/ldapuser.ldif
ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w ${ADMIN_PASSWD} -f ldifs/ldapuser.ldif

# Phpldapadmin setup
sudo yum --enablerepo=epel -y install phpldapadmin
sudo sed -i '397 s;// $servers;$servers;' /etc/phpldapadmin/config.php
sudo sed -i '398 s;$servers->setValue;// $servers->setValue;' /etc/phpldapadmin/config.php
sudo sed -i ' s;Require local;Require all granted;' /etc/httpd/conf.d/phpldapadmin.conf
sudo sed -i ' s;Allow from 127.0.0.1;Allow from 0.0.0.0;' /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd
