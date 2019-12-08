#!/usr/bin/env bash

### This script will run on ansible via RS node
### All actions will be logged to file /home/ubuntu/addlog.out
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ubuntu/addlog.out 2>&1

### Connect to ansible master and run commands: add ip to /etc/ansible/hosts and run playbook which will change the clone to a new values
date
if [[ $(grep -n "$1" /etc/ansible/hosts | wc -l) == 0 ]]; then
  cd /etc/ansible
  echo "$1" | sudo tee -a /etc/ansible/hosts
  /usr/bin/ansible-playbook -i hosts playbook.yml --key-file="/home/ubuntu/javakey.pem" -v
else
  echo "$1 already exist in hosts file"
fi
EOF
exit 0

