#!/bin/bash
### add log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ubuntu/droplog.out 2>&1


###Get private  ip
private_ip=$(/usr/bin/curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo $private_ip

### Connect to ansible master and run commands: drop ip from /etc/ansible/hosts and run playbook which will remove ip from /etc/pgpool/pgpool.conf
/usr/bin/ssh ubuntu@172.31.41.41 << EOF
if [[ $(grep -n "$private_ip" /etc/ansible/hosts | wc -l) > 0 ]]; then
  sed -i "/$private_ip/d" /etc/ansible/hosts
  cd /etc/ansible
  /usr/bin/ansible-playbook -i hosts drop_backend.yml --extra-vars "private_backend_ip=$private_ip" -v 
else
  echo "$private_ip doesn't exist in hosts file"
fi
EOF
