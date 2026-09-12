bash: service: command not found
(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ mysql -h locahost -P -u root -p
bash: mysql: command not found
(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ python3 -c "import mysql.connector; c=mysql.connector.connect(host='localhost', port=3306, user='root', password='root', database='cedera'); print('CONNECTED'); c.close()"
Traceback (most recent call last):
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/network.py", line 795, in open_connection
    self.sock.connect(sockaddr)
ConnectionRefusedError: [Errno 111] Connection refused

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/pooling.py", line 323, in connect
    return MySQLConnection(*args, **kwargs)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/connection.py", line 185, in __init__
    self.connect(**kwargs)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/abstracts.py", line 1604, in connect
    self._open_connection()
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/connection.py", line 411, in _open_connection
    raise err
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/connection.py", line 382, in _open_connection
    self._socket.open_connection()
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/network.py", line 806, in open_connection
    raise InterfaceError(
mysql.connector.errors.InterfaceError: 2003: Can't connect to MySQL server on 'localhost:3306' (Errno 111: Connection refused)
(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ 
