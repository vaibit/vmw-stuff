**vyos config**
https://docs.vyos.io/en/equuleus/quick-start.html

    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 default-router '192.168.1.1'    
    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 name-server '192.168.1.1'    
    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 domain-name 'vyos.net'    
    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 lease '86400'    
    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 start 192.168.1.9    
    set service dhcp-server shared-network-name LAN subnet 192.168.1.0/24 range 0 stop '192.168.1.254'
    
      
    
    set service dns forwarding cache-size '0'    
    set service dns forwarding listen-address '192.168.1.1'    
    set service dns forwarding allow-from '192.168.1.0/24'    
      
    
    set nat source rule 100 outbound-interface 'eth0'    
    set nat source rule 100 source address '192.168.1.0/24'    
    set nat source rule 100 translation address masquerade

    #vcd vapp:      
    
    #Network    
    eth_0_ip 192.168.0.254    
    eth_0_ip_mask 255.255.255.0    
    eth_1_ip 192.168.1.254    
    eth_1_ip_mask 255.255.255.0    
    eth_2_ip 192.168.2.254    
    eth_2_ip_mask 255.255.255.0
    eth_3_ip 192.168.3.254    
    eth_3_ip_mask 255.255.255.0
    default_gw 192.168.0.1
    additional_args
    bootstrap_cmd
    
    set service ssh port 22    
    set nat source rule 11 outbound-interface eth0    
    set nat source rule 11 source address 0.0.0.0/0    
    set nat source rule 11 translation address masquerade    
    set protocols bgp local-as 200    
    set protocols bgp neighbor 192.168.2.253 remote-as 300    
    set protocols bgp address-family ipv4-unicast redistribute connected    
    set protocols bgp neighbor 192.168.2.253 address-family ipv4-unicast    
    set system login user vyos authentication plaintext-password MyS3cur3Pa$$w0rd    
    set nat destination rule 9 destination port 3389    
    set nat destination rule 9 inbound-interface eth0    
    set nat destination rule 9 protocol tcp    
    set nat destination rule 9 translation address 192.168.1.90    
    set nat destination rule 10 destination port 22    
    set nat destination rule 10 inbound-interface eth0
    set nat destination rule 10 protocol tcp    
    set nat destination rule 10 translation address 192.168.1.92    
    set nat destination rule 11 destination port 80    
    set nat destination rule 11 inbound-interface eth0    
    set nat destination rule 11 protocol tcp    
    set nat destination rule 11 translation address 192.168.1.92    
    set nat destination rule 12 destination port 443    
    set nat destination rule 12 inbound-interface eth0    
    set nat destination rule 12 protocol tcp    
    set nat destination rule 12 translation address 192.168.1.92
    echo 0 > /home/vyos/.bash_history