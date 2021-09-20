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

vlan.201 201 192.168.200.1/31.  

The structure of the file is this:

device    vlan_id    ip_address/mask  

The script parses each file and either adds a netns or re-configures exsisting one. NOTICE that the main interface on which all the sub-interfaces are created is  hardcoded into the script as ens4. This means it must be created prior to running the script with the service. I used netplan and the following yaml file under /etc/netplan to account for the ens4 interface:

cat /etc/netplan/02-netcfg.yaml  
\# This file describes the network interfaces available on your system  
\# For more information, see netplan(5).  
network:  
  version: 2  
  renderer: networkd  
  ethernets:  
    ens4:  
      match:  
        name: ens4  
  vlans:  
    vlan.2:  
      id: 2  
      link: ens4  
      dhcp4: no  
      addresses: [ 192.168.200.1/31 ]   


The vlan.2 sub-interface is used in the default network namespace to provide a means for synchronization for systemd-timesyncd service on the jump host - this is specific to my lab. You may opt to getting ntp data from publicly available ntp servers.

Deleting network namespaces is currently not supported - this functionality will  be added in one of the next commits.  



