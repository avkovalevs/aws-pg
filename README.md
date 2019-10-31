PG Cluster tuning playbook
=========

The goal is to create a PostgreSQL cluster with Fault-tolerant, Load Balancing inside of AWS Auto Scaling Group using Spot EC2 instances. 
The main idea is to use AWS Spot instances for base nodes and additional slave instances. In the case of increased workload, Auto Scaling group must add more slave nodes. The cluster consists of 3 base nodes: master(+pgpool), special slave (+pgpool), usual slave (without pgpool). The usual slave will be used as a 'gold image' for cloning to additional slave instances. 
The base nodes have a static IP primary addresses. Additional nodes can use dynamic IP. AWS Security Group for PG nodes need to open ports 22, 5432, 9999, 9898, 9000.  

Requirements
------------
Ubuntu 16.04 LTS, Ansible 2.8.5, PostgreSQL 9.6, Repmgr 5.0.0, Pgpool 4.0.6

Components and Concept.
--------------
1. Ansible. 
It will automatically deploy and manage PG cluster. 
It is required to install Ansible software inside the private network. Ansible will connect to targets (PG nodes) via ssh. There is need to tune passwordless access between Ansible host and each of the PG host using RSA keys. Currently, access tuned between Ubuntu user of Ansible node and Ubuntu user of PG nodes. 
2. PG nodes.
Playbooks will tune passwordless access between Postgres system's users of all PG nodes. It is a requirement of PostgreSQL streaming replication.  
3. PGPool nodes.
They are located on base PG nodes and communicate between Application Tier and Database Tier. The Application tier will connect to Virtual IP (Floating IP) one of the PGPool nodes - Master on 9999 port and it will balance worload between all PG nodes. In case of Master failure VIP address will move to Slave node and promote to a new Master. Both PGPool nodes will communicate each other using Watchdog healthcheck process.
Also PGPool nodes will do a healthcheck of PG nodes (backends) and in case if the Primary DB will fail and promote on Replica DB then PGPool Master will move read-write queries to a new Master. The typical time to determine a failure is about 20-30 seconds, after the Slave with high priority will be promoted to a new Master (10-20seconds). The common time on failover not prevent one minute.  

Install Ansible software
---------------
It is required to install Ansible software inside the private network which has an access using ssh to database nodes. This node must have an Internet access to install software from public repositories to target nodes. 
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
If Ansible host and database hosts are accesible to both end via common private network then need to change 'hosts' file on privatedatabase addresses. In case of database hosts and ansible host has passwordless access between Ubuntu users then option --key-fileno need to be specified. 
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
6.1 AWS steps to use floating IP. The floating IP configuration need to use in Pgpool cluster.  
Currently, AWS does not fully support floating IP for Ubuntu 16.04 LTS. This means, that setting a static primary and secondary ip  via Actins->Networking->Manage IP Addresses not working dynamically and even after the shutdown/startup. For correct network settings change on master database node network config files '/etc/network/interfaces' and 99-disable-network-config.cfg as shown in example at github. The first file will add primary and secondary ip addresses. The second file will disable cloud network configuration and use standard Ubuntu network configuration. To apply network changes need to run following command:
```
$ sudo systemctl restart networking
The correct primary and secondary ip addresses must be looking like these (second row starting with eth0):
$ ip --brief a s 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             172.31.41.51/20 172.31.41.52/20 fe80::88b:c5ff:fe78:f372/64 
```
6.2 Other steps need to be implemented according to note https://aws.amazon.com/ru/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/ 
Also I checked that secondary ip not installed correctly even after the launch wizard instance (create EC2 instance). 
The cloud init network config file /etc/network/interfaces.d/50-cloud-init.cfg not contain required settings.
Settings will return to original values after reboot even if they were set manually.


Useful links: 
--------
https://www.pgpool.net/docs/latest/en/html/example-aws.html
https://aws.amazon.com/ru/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/
https://aws.amazon.com/ru/premiumsupport/knowledge-center/ec2-virtual-ip-monitor-script-fails/

-------
License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
