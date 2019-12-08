#!/bin/bash

###Get private  ip
private_ip=$(/usr/bin/curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo $private_ip

### Connect to ansible master and run commands: add ip to /etc/ansible/hosts and run playbook which will add RS as backend to pgcluster
/usr/bin/ssh ubuntu@172.31.41.41 "/etc/ansible/add.sh $private_ip"
exit 0

