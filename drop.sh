#!/usr/bin/env bash

### This script will run on ansible via RS node
### All actions will be logged to file /home/ubuntu/addlog.out
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ubuntu/droplog.out 2>&1

set -x
echo "$1"
date
echo $(hostname)
if [[ $(sudo grep -n "$1" /etc/ansible/hosts | wc -l) > 0 ]]; then
  echo $(hostname)
  sudo sed -i /"$1"/d /etc/ansible/hosts
  cd /etc/ansible
  /usr/bin/ansible-playbook -i hosts drop_backend.yml --extra-vars "private_backend_ip=$1" -v         
else
  echo $private_ip does not exist in hosts file
fi

