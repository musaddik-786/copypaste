(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ ping -c 2 LTCH-9DT24253GP
ping: LTCH-9DT24253GP: Name or service not known
(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ python3 -c "import socket; print(socket.gethostbyname('LTCH-9DT24253GP'))"
Traceback (most recent call last):
  File "<string>", line 1, in <module>
socket.gaierror: [Errno -2] Name or service not known
(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ 
