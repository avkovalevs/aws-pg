PG Cluster tuning playbook
=========

The goal is to create a PostgreSQL cluster with Fault-tolerant, Load Balancing using AWS Auto Scaling Group (ASG) of Spot EC2 instances. 2 of EC2 Spot instances (base nodes with pgpool installed) will not be located in ASG. Other nodes will be located inside the ASG. Base nodes are not located inside the ASG because these nodes must use static private IP address.
The main idea is to use AWS Spot instances for base nodes and additional slave instances for select workload. In case of increased workload, ASG will add more slave nodes depending on CPU Usage parameter (by default 80%). The cluster consists of 2 base nodes: PG-master+pgpool, special PG-slave+pgpool. A regular slave(-s) will not have pgpool installed and they will not participate in failover operations. The image of regular slave will be used as a 'gold image' for cloning to additional slave instances.
The base nodes will have a static IP primary addresses for node communication and VIP as secondary private IP for Pgpool. VIP will be used as entrypoint to Application tier. Additional nodes in ASG use dynamic private IP addresses. AWS Security Group for all PG nodes need to open ports 22/tcp, 5432/tcp, 9999/tcp, 9898/tcp, 9000/tcp, 9694/udp. For deployment a base nodes there is need to use Ansible master node which has an access to PG nodes by ssh using keys.

Software requirements
------------
Ubuntu 16.04 LTS, Ansible 2.8.5, PostgreSQL 9.6.15, Repmgr 5.0.0, Pgpool 4.0.6, AWS cli 1.16.278.

Components and Concept.
--------------
1. Ansible master. 
It will automatically deploy and manage PG cluster. It is anough to use t2.nano EC2 instance for Ansible. It is required to install Ansible software inside the private network on separate node and be avaliable all time. Ansible will connect to targets (PG nodes) via ssh. There is need to tune passwordless access between Ansible host and each of the PG host using RSA keys. Currently, access tuned between Ubuntu user of Ansible node and Ubuntu user of PG nodes. 
2. PG nodes.
There are 3 type of PG nodes: PG Master (M), PG Special Slave (SS) and Regular Slave (RS) located in Auto Scaling Group.
The RS will not participate in failover and failback operations as SS. The SS contain a PGPool software, but RS not.
The HA/DR solution for PostgreSQL is streaming replication which managed by REPMGR.  
Playbooks will tune passwordless access between Postgres system's users of all PG nodes. It is a requirement of PostgreSQL streaming replication.  
3. PGPool nodes.
They are located on base PG nodes and communicate between Application Tier and Database Tier. The Application tier will connect to Virtual IP (Floating IP) one of the PGPool nodes - Master on 9999 port and it will balance worload between all PG nodes. In case of Master failure VIP address will move to Slave node and promote to a new Master. Both PGPool nodes will communicate each other using Watchdog healthcheck process.
Also PGPool nodes will do a healthcheck of PG nodes (backends) and in case if the Primary DB will fail and promote on Replica DB then PGPool Master will move read-write queries to a new Master. The typical time to determine a failure is about 20-30 seconds, after the Slave with high priority will be promoted to a new Master (10-20seconds). The common time on failover not prevent one minute.  

Install Ansible software
---------------
It is required to install Ansible software inside the private network which has an access using ssh to database nodes. This node must have an Internet access to install software from public repositories to target nodes. 
```
$ sudo apt-add-repository ppa:ansible/ansible
$ sudo apt install software-properties-common -y
$ sudo apt update
$ sudo apt install ansible -y
$ sudo apt install python-psycopg2 -y
$ sudo apt install python-netaddr -y
```
How to use:
----------------
1. Clone playbooks from github repo https://github.com/iddozo/DBCluster.git to /etc/ansible catalog.

2. Add the Ansible-vault file .vault_pass.txt to ubuntu user's $HOME catalog (get it from #avkovalevs)
This file is used as the key to decrypt the creds.yml.
The creds.yml file store the passwords variables which are used inside the playbook.yml.
Add this string below to end of file /home/ubuntu/.profile and run $ . ~/.profile
ANSIBLE_VAULT_PASSWORD_FILE=/home/ubuntu/.vault_pass.txt 
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
3. Prepare AWS environment:
3.1 add rules to Security Group 1 with open ports 22, 5432, 9999, 9898, 9000, 9694/udp for private network (for example 172.31.31.0/24 subnet) and open 22 port to public network.
3.2 add ec2 instances - primary master and slave (base nodes). If they are already exist, then skip this step.
3.3 assign ec2 instances to Security Group 1.
3.4 for master node need to setup a static ip for eth0 network enterface in AWS console (Actions->Networking->Manage IP addresses, add the secondary private ip for VIP). One private and one public IP are already setup by AWS. The second private IP need to be added manually. 
3.5 Assign Elastic IP to Master Node with reassignment option. 
4. Start to deploy PG infrastructure:
If Ansible host and database hosts are located in common private network then need to add to /etc/ansible/hosts file private addresses from both nodes. In case of the database hosts and ansible host has passwordless access between Ubuntu users then option --key-file no need to be specified. 
```
[ubuntu@ans-host:/etc/ansible]$ ansible-playbook -i hosts playbook.yml --key-file="/home/ubuntu/javakey.pem" -v
```
Before starting you need to change the hosts file and check variables inside the roles:
```
./roles/postgres/defaults/main.yml  
./roles/pgpool/defaults/main.yml  
./roles/common/defaults/main.yml  

```
All tasks must be completed without errors. 
5. After the deployment you need to check the state of postgres, pgpool and repmgr services on base nodes.
5.1 Postgresq (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status postgresql@9.6-main.service
● postgresql@9.6-main.service - PostgreSQL Cluster 9.6-main
   Loaded: loaded (/lib/systemd/system/postgresql@.service; disabled; vendor preset: enabled)
   Active: active (running) since Fri 2019-10-25 16:35:30 UTC; 1 day 22h ago
```
5.2 Pgpool (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status pgpool2.service 
● pgpool2.service - pgpool-II
   Loaded: loaded (/lib/systemd/system/pgpool2.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2019-10-25 16:35:38 UTC; 1 day 22h ago
```
5.3 Repmgrd (OK status)
```
ubuntu@ip-172-30-0-235:~$ systemctl status repmgrd
● repmgrd.service - LSB: Start/stop repmgrd
   Loaded: loaded (/etc/init.d/repmgrd; bad; vendor preset: enabled)
   Active: active (running) since Thu 2019-10-24 12:14:59 UTC; 3 days ago
```
On PG master you can see 'wal sender' processes, on PG slave nodes 'wal receiver' processes accordingly. 
The number of 'wal sender' processes is equal to number of slaves (or replicas).

Check the network access between PG nodes using nmap, example below:
ubuntu@ip-172-30-0-235:~$ nmap 172.30.0.12

Starting Nmap 7.01 ( https://nmap.org ) at 2019-11-07 18:39 UTC
Nmap scan report for ip-172-30-0-12 (172.30.0.12)
Host is up (0.00049s latency).
Not shown: 995 filtered ports
PORT     STATE  SERVICE
22/tcp   open   ssh
80/tcp   open   http
5432/tcp open   postgresql
9898/tcp open   monkeycom
9999/tcp open   abyss

6. Check the cluster state.

7. AWS specific network settings for Pgpool nodes.     
7.1 AWS steps to use floating IP. The floating IP configuration need to use in Pgpool cluster.  
Currently, AWS does not fully support floating IP for Ubuntu 16.04 LTS. This means, that setting a static primary and secondary ip  via Actins->Networking->Manage IP Addresses not working dynamically and even after the shutdown/startup. For correct network settings change on master database node network config files '/etc/network/interfaces' and 99-disable-network-config.cfg as shown in example at github. The first file will add primary and secondary ip addresses. The second file will disable cloud network configuration and use standard Ubuntu network configuration. To apply network changes need to run following command:
```
$ sudo systemctl restart networking
The correct primary and secondary ip addresses must be looking like these (second row starting with eth0):
$ ip --brief a s 
lo               UNKNOWN        127.0.0.1/8 ::1/128 
eth0             UP             172.31.41.51/20 172.31.41.52/20 fe80::88b:c5ff:fe78:f372/64 
```
7.2 Other steps need to be implemented according to note https://aws.amazon.com/ru/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/ 
Also I checked that secondary ip not installed correctly even after the launch wizard instance (create EC2 instance). 
The cloud init network config file /etc/network/interfaces.d/50-cloud-init.cfg not contain required settings.
Settings will return to original values after reboot even if they were set manually.


Useful links: 
--------
https://www.pgpool.net/docs/latest/en/html/example-aws.html
https://aws.amazon.com/ru/articles/leveraging-multiple-ip-addresses-for-virtual-ip-address-fail-over-in-6-simple-steps/
https://aws.amazon.com/ru/premiumsupport/knowledge-center/ec2-virtual-ip-monitor-script-fails/
https://habr.com/ru/post/213409/
-------
License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
