#!/bin/bash
#Script to setup new system

# Regenerating UUID
echo "Generating system UUID"
ssh root@$ip rm -f /etc/machine-id /var/lib/dbus/machine-id
ssh root@$ip dbus-uuidgen --ensure=/etc/machine-id
ssh root@$ip dbus-uuidgen --ensure

# Configure new hostname
read -p "Enter the new hostname: " new_hostname
ssh root@$ip nmcli general hostname $new_hostname

# Join the domain
echo "Joining the domain"
ssh root@$ip read -p "Enter the domain name: " domain_name
ssh root@$ip read -p "Enter the domain admin username: " admin_username
ssh root@$ip realm join "$domain_name" -U "$admin_username"

# Configure SSSD
echo "Configuring SSSD"
ssh root@$ip sed -i '6i default_domain_suffix = jmpnetwork.com' /etc/sssd/sssd.conf
ssh root@$ip sed -e '/services = nss, pam/ s/^#*/#/' -i /etc/sssd/sssd.conf

# Configure permissions
echo "Configuring permissions"
ssh root@$ip realm permit -g 'LinuxAdmins'
ssh root@$ip sed -i '$ a '%LinuxAdmins@jmpnetwork.com'     ALL=(ALL)       NOPASSWD: ALL' /etc/sudoers

# Enable automatic home directory creation
echo "Enabling automatic home directory creation"
ssh root@$ip pam-auth-update --enable mkhomedir

# Enable Linux hardening
echo "Enabling Linux hardening"
ssh root@$ip sed -i '$ a 0 */6 * * *     root    /scripts/harden.sh' /etc/crontab

# Reboot system
echo "Rebooting system"
ssh root@$ip reboot
