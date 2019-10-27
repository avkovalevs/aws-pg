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

Recommendations
---------------
It is required to install Ansible software inside the private network which has the network access via ssh to database nodes. 
```
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt install software-properties-common
$ sudo apt update
$ sudo apt install ansible
$ sudo python-psycopg2 
```
How to use:
----------------
1. Clone playbooks from github repo https://github.com/iddozo/DBCluster.git to /etc/ansible catalog.

2. Add the Ansible-vault file .vault_pass.txt to ubuntu user's $HOME catalog (get it from #avkovalevs)
This file is used as the key to decrypt the creds.yml.
The creds.yml file store the passwords variables which are used inside the playbook.yml.
To change variables inside the creds.yml file use the following commands:
```
$ sudo ansible-vault decrypt creds.yml
```
Change the file creds.yml using vi editor. 
The final step is encrypt the file:
```
$ sudo ansible-vault encrypt creds.yml   
```
The secret variables will be decrypted temporary in memory during the playbook run. They are not shown in std output and logs.

3. Start to deploy PG infrastructure:
```
[ubuntu@ans-host:/etc/ansible]$ ansible-playbook -i hosts playbook.yml --key-file="/home/ubuntu/javakey.pem" -v
```
Before starting you need to change the hosts file and check variables inside the roles:
```
./roles/postgres/defaults/main.yml  
./roles/pgpool/defaults/main.yml  
./roles/common/defaults/main.yml  

```
4. After the deployment check the state of postgres, pgpool and repmgr services on base nodes.
4.1 Postgresq (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status postgresql@9.6-main.service
● postgresql@9.6-main.service - PostgreSQL Cluster 9.6-main
   Loaded: loaded (/lib/systemd/system/postgresql@.service; disabled; vendor preset: enabled)
   Active: active (running) since Fri 2019-10-25 16:35:30 UTC; 1 day 22h ago
```
4.2 Pgpool (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status pgpool2.service 
● pgpool2.service - pgpool-II
   Loaded: loaded (/lib/systemd/system/pgpool2.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2019-10-25 16:35:38 UTC; 1 day 22h ago
```
4.3 Repmgrd (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status repmgrd
● repmgrd.service - LSB: Start/stop repmgrd
   Loaded: loaded (/etc/init.d/repmgrd; bad; vendor preset: enabled)
   Active: active (running) since Thu 2019-10-24 12:14:59 UTC; 3 days ago
```
5. Check the cluster state.

6. AWS network tuning
AWS steps to use floating IP. The floating IP configuration need to use in Pgpool cluster.
Currently, AWS does not fully support floating IP for Ubuntu 16.04 LTS. This means, that setting a static primary and secondary ip  via Actins->Networking->Manage IP Addresses not working dynamically and even after the shutdown/startup. For correct network settings change on master database node network config files '/etc/network/interfaces' and 99-disable-network-config.cfg as shown in example at github. The first file will add primary and secondary ip addresses. The second file will disable cloud network configuration and use standard Ubuntu network configuration. Other steps need to be implemented according to note https://aws.amazon.com/ru/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/ 
 Also I checked that secondary ip not installed correctly even after the launch wizard instance (create EC2 instance). 
The cloud init network config file /etc/network/interfaces.d/50-cloud-init.cfg not contain required settings.
If I changed setting manually they are changed after reboot to initial values. 
License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
