JarvisClaims@JarvisClaims:~/Musaddique$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 7c:1e:52:cb:d0:0d brd ff:ff:ff:ff:ff:ff
    inet 10.0.0.4/24 metric 100 brd 10.0.0.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::7e1e:52ff:fecb:d00d/64 scope link 
       valid_lft forever preferred_lft forever
3: enP61500s1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc mq master eth0 state UP group default qlen 1000
    link/ether 7c:1e:52:cb:d0:0d brd ff:ff:ff:ff:ff:ff
    altname enP61500p0s2
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 72:a6:8c:de:fa:c9 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
JarvisClaims@JarvisClaims:~/Musaddique$ ip route
default via 10.0.0.1 dev eth0 proto dhcp src 10.0.0.4 metric 100 
10.0.0.0/24 dev eth0 proto kernel scope link src 10.0.0.4 metric 100 
10.0.0.1 dev eth0 proto dhcp scope link src 10.0.0.4 metric 100 
168.63.129.16 via 10.0.0.1 dev eth0 proto dhcp src 10.0.0.4 metric 100 
169.254.169.254 via 10.0.0.1 dev eth0 proto dhcp src 10.0.0.4 metric 100 
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 linkdown 
JarvisClaims@JarvisClaims:~/Musaddique$ 
