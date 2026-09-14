Linux has Bash's built-in /dev/tcp, so run:

timeout 5 bash -c '</dev/tcp/10.6.2.27/3360' && echo "CONNECTED" || echo "FAILED"

This is much more useful than ping because your actual requirement is TCP/MySQL connectivity, not ICMP.

Then also run:

ip route get 10.6.2.27
