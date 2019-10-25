PG Cluster tuning playbook
=========

The goal is to create a PostgreSQL cluster with Fault-tolerant, Load Balancing inside of AWS Auto Scaling Group using Spot EC2 instances. 
The main idea is to use AWS Spot instances for base nodes and additional slave instances. In the case of increased workload, Auto Scaling group must add more slave nodes. The cluster consists of 3 base nodes: master(+pgpool), special slave (+pgpool), usual slave (without pgpool). The usual slave will be used as a 'gold image' for cloning to additional slave instances. 


Requirements
------------
Ubuntu 16.04 LTS, Ansible 2.8.5, PostgreSQL 9.6, Repmgr 5.0.0, Pgpool 4.0.6

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

How to use:
----------------
1. Clone playbooks from github repo https://github.com/iddozo/DBCluster.git to /etc/ansible catalog.
The final content must be looking like this:
ubuntu@dbsrv2:/etc/ansible$ ls -la
total 52
drwxr-xr-x  4 root root  4096 Oct 25 17:55 .
drwxr-xr-x 99 root root  4096 Oct 25 13:37 ..
drwxr-xr-x  8 root root  4096 Oct 25 17:02 .git
-rw-r--r--  1 root root  1579 Oct 25 17:54 README.md
-rw-r--r--  1 root root 20039 Oct 24 21:00 ansible.cfg
-rw-r--r--  1 root root   679 Oct 24 20:53 creds.yml
-rw-r--r--  1 root root   963 Oct 23 18:25 hosts
-rw-r--r--  1 root root   766 Oct 25 14:09 playbook.yml
drwxr-xr-x  5 root root  4096 Oct 18 21:05 roles

2. Add Ansible-vault file .vault_pass.txt to ubuntu user's $HOME catalog (get it from #avkovalevs)
This file used as key for decrypt the creds.yml.
The creds.yml file store the passwords variables used inside the playbooks.

3. Start to deploy PG infrastructure:
[ubuntu@ans-host:/etc/ansible]$ ansible-playbook -i hosts playbook.yml --key-file="/home/ubuntu/javakey.pem" -v

Before starting need to change the hosts file and check variables inside the roles:
./roles/postgres/defaults/main.yml
./roles/pgpool/defaults/main.yml
./roles/common/defaults/main.yml

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
