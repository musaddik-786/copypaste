JarvisClaims@JarvisClaims:~/Musaddique$ ping -c 4 10.0.0.1
PING 10.0.0.1 (10.0.0.1) 56(84) bytes of data.

--- 10.0.0.1 ping statistics ---
4 packets transmitted, 0 received, 100% packet loss, time 3052ms

JarvisClaims@JarvisClaims:~/Musaddique$ ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=115 time=5.17 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=115 time=5.29 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=115 time=5.46 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=115 time=5.67 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 5.171/5.398/5.674/0.189 ms
JarvisClaims@JarvisClaims:~/Musaddique$ nc -vz 10.6.2.27 3360
bash: nc: command not found
JarvisClaims@JarvisClaims:~/Musaddique$ 
