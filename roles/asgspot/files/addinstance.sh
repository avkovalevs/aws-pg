#!/bin/bash

### Don't start this script on ansible, PG master and PG special slave
### This script must be started only on the regular slaves at AWS Auto Scaling Group 
### All actions will be logged to file /home/ubuntu/addlog.out
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ubuntu/addlog.out 2>&1

###Get private  ip
private_ip=$(/usr/bin/curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo $private_ip

### Connect to ansible master and run commands: add ip to /etc/ansible/hosts and run playbook which will change the clone to a new values
/usr/bin/ssh ubuntu@172.31.41.41 << EOF
if [[ $(grep -n "$private_ip" /etc/ansible/hosts | wc -l) == 0 ]]; then
  echo "$private_ip" | sudo tee -a /etc/ansible/hosts
  cd /etc/ansible
  /usr/bin/ansible-playbook -i hosts playbook.yml -v 
else
  echo "$private_ip already exist in hosts file"
fi
EOF
