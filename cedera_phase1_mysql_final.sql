JarvisClaims@JarvisClaims:~/Musaddique$ timeout 5 bash -c '</dev/tcp/10.6.2.27/3360' && echo "CONNECTED" || echo "FAILED"
FAILED
JarvisClaims@JarvisClaims:~/Musaddique$ ip route get 10.6.2.27
10.6.2.27 via 10.0.0.1 dev eth0 src 10.0.0.4 uid 1000 
    cache 
JarvisClaims@JarvisClaims:~/Musaddique$ 
