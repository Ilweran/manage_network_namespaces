# manage_network_namespaces
The service manages CRUD operations for network namespaces on a Ubuntu Linux host. It uses a bash script located in /usr/sbin,
 as well as a directory following /home/lab/ns/, which contains files with network namespace definition. Take a look at the below output:
cfg01-jump:/home/lab/ns# ll
total 28
drwxr-xr-x 2 root root 4096 Sep 20 06:23 ./
drwxr-xr-x 6 lab  lab  4096 Sep 10 17:36 ../
-rw-r--r-- 1 root root   30 Sep 10 17:39 cust_a
-rw-r--r-- 1 root root   30 Sep 20 06:03 isp_as1
-rw-r--r-- 1 root root   30 Sep 10 17:39 isp_as12
-rw-r--r-- 1 root root   30 Sep 10 17:39 isp_as3
-rw-r--r-- 1 root root   30 Sep 10 17:39 isp_as7
cfg01-jump:/home/lab/ns# 
Each files must be named after the name of corresponding netns. Each file contains lines that describe interfaces in the network namespace like the following:
vlan.201 201 192.168.200.1/31
The structure of the file is this:
device    vlan_id    ip_address/mask
The script parses the file and either adds a netns or re-configures exsisting one. Deleting network namespaces is currently not supported - this functionality will be added in one of the next commits.



