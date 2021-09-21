#!/bin/bash

NETNS_FILES="/home/lab/ns/*"
NETNS_DIR="/home/lab/ns/"

ns_list=$(ip netns list)


edit_netns_interface () {
  
  # $1 - netns, $2 - int, $3 - vlan_id, $4 - ip_add
  ip netns exec $1 ip link del $2
  ip link add link ens4 name $2 type vlan protocol 802.1Q id $3
  ip link set $2 netns $1
  ip netns exec $1 ip link set dev $2 up
  ip netns exec $1 ip addr add $4 dev $2

}

create_configure_netns () {

  # $1 - netns, $2 - int, $3 - vlan_id, $4 - ip_add
  if [[ "$ns_list" != *"$1"* ]]
  then
    ip netns add $1
  fi
  ip link add link ens4 name $2 type vlan protocol 802.1Q id $3
  ip link set $2 netns $1
  ip netns exec $1 ip link set dev $2 up
  ip netns exec $1 ip addr add $4 dev $2

}

ip link set dev ens4 up

if [[ "$(ip netns list | wc -l)" > "$(ls "$NETNS_DIR" | wc -l)" ]]; then

  #Delete netns for which there is no file in the $NETNS_DIR
  for netnslist in $(ip netns list | awk '{print $1}'); do
    netns_array+=("$netnslist")
  done
  for netnsfile in $(ls -l "$NETNS_DIR" | grep "\-rw" | awk '{print $9}'); do
    for i in "${!netns_array[@]}"; do
      if [[ ${netns_array[i]} = $netnsfile ]]; then
        unset 'netns_array[i]'
      fi
    done
  done
  for i in "${!netns_array[@]}"; do
    printf "\n**  Deleting ${array[i]} network namespace  **\n"
    ip netns delete "${netns_array[i]}"
  done

elif [[ "$(ip netns list | wc -l)" < "$(ls "$NETNS_DIR" | wc -l)" ]]; then

  #Create and configure netns from it's file under $NETNS_DIR
  for netnsfile in $(ls -l "$NETNS_DIR" | grep "\-rw" | awk '{print $9}'); do
    netnsfile_array+=("$netnsfile")
  done
  for netns in $(ip netns list | awk '{print $1}'); do
    for i in "${!netnsfile_array[@]}"; do
      if [[ ${netnsfile_array[i]} = $netns ]]; then
        unset 'netnsfile_array[i]'
      fi    
    done
  done
  for i in "${!netnsfile_array[@]}"; do
    new_array+=( "${netnsfile_array[i]}" )
  done
  netnsfile_array=("${new_array[@]}")
  unset new_array
  for i in "${!netnsfile_array[@]}"; do
    printf "\n**  Adding and configuring ${netnsfile_array[i]} network namespace  **\n"
    while read line; do
      interface=$(echo $line | awk '{print $1}')
      vlan=$(echo $line | awk '{print $2}')
      ipaddress=$(echo $line | awk '{print $3}')
      printf "\n***************************************************************************************\n"
      printf "\n**    Creatig and configuring the "${netnsfile_array[i]}" network namespace.         **\n"
      printf "\n***************************************************************************************\n"
      create_configure_netns "${netnsfile_array[i]}" "$interface" "$vlan" "$ipaddress"
      printf "\n***************************************************************************************\n"
      printf "\n**             Configured $interface interface in $ns network namespace.             **\n"
      printf "\n***************************************************************************************\n"
      printf "\n***************************************************************************************\n"
      printf "\n**$interface interface is in "${netnsfile_array[i]}" network namespace and has $ipaddress address    **\n"
      printf "\n***************************************************************************************\n\n"
    done < /home/lab/ns/${netnsfile_array[i]}
  done

else

  #Check if reconfiguration of some netspace is required
  for f in $NETNS_FILES; do
    ns=$(echo $f | cut -d "/" -f 5)
    if [[ "$ns_list" == *"$ns"* ]]
    then
      printf "\n***************************************************************************************\n"
      printf "\n** The $ns network namespace already exists. Checking if re-configuration is needed. **\n"
      printf "\n***************************************************************************************\n"
      tmp_interface=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/\@.*//')
      tmp_vlan=$(ip netns exec $ns ip a | egrep "vlan.*if" | awk '{print $2}' | sed 's/vlan\.//' | sed 's/\@.*//')
      tmp_ipaddress=$(ip netns exec $ns ip a | egrep "inet 192" | awk '{print $2}')
      while read line; do
        interface=$(echo $line | awk '{print $1}')
        vlan=$(echo $line | awk '{print $2}')
        ipaddress=$(echo $line | awk '{print $3}')
        if [[ ( "$interface" != "$tmp_interface" ) || ( "$vlan" != "$tmp_vlan" ) || ( "$ipaddress" != "$tmp_ipaddress" ) ]]; then
          printf "\n***************************************************************************************\n"
          printf "\n**                 An interface in the $ns network namespace has changed.            **\n"
          printf "\n***************************************************************************************\n"
          printf "\n***************************************************************************************\n"
          printf "\n**                                  Reconfiguring                                    **\n"
          printf "\n***************************************************************************************\n"
          edit_netns_interface "$ns" "$interface" "$vlan" "$ipaddress"
          printf "\n***************************************************************************************\n"
          printf "\n**      The $interface interface in the $ns network namespace was reconfigured.      **\n"
          printf "\n***************************************************************************************\n\n"
        else
          printf "\n***************************************************************************************\n"
          printf "\n**      The $ns network namespace already exists and no reconfiguration is needed.   **\n"
          printf "\n***************************************************************************************\n"
          printf "\n***************************************************************************************\n"
          printf "\n**                                    Skipping...                                    **\n"
          printf "\n***************************************************************************************\n\n"
        fi
    done < /home/lab/ns/$ns
    continue
    fi
  done
fi
