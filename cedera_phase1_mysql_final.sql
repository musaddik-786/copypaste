(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ python3 main.py 
INFO:     Started server process [16357]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:7720 (Press CTRL+C to quit)
INFO:     127.0.0.1:54340 - "GET /api/v1/treaty_management_mcp/docs HTTP/1.1" 200 OK
INFO:     127.0.0.1:54340 - "GET /api/v1/treaty_management_mcp/openapi.json HTTP/1.1" 200 OK
INFO:     127.0.0.1:54334 - "POST /api/v1/treaty_management_mcp/treaty_management_mcp HTTP/1.1" 500 Internal Server Error
ERROR:    Exception in ASGI application
Traceback (most recent call last):
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/mysql/connector/network.py", line 795, in open_connection
    self.sock.connect(sockaddr)
ConnectionRefusedError: [Errno 111] Connection refused

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/uvicorn/protocols/http/h11_impl.py", line 416, in run_asgi
    result = await app(  # type: ignore[func-returns-value]
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/uvicorn/middleware/proxy_headers.py", line 63, in __call__
    return await self.app(scope, receive, send)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/applications.py", line 1163, in __call__
    await super().__call__(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/applications.py", line 96, in __call__
    await self.middleware_stack(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/errors.py", line 186, in __call__
    raise exc
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/errors.py", line 164, in __call__
    await self.app(scope, receive, _send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/cors.py", line 96, in __call__
    await self.simple_response(scope, receive, send, request_headers=headers)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/cors.py", line 154, in simple_response
    await self.app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/exceptions.py", line 63, in __call__
    await wrap_app_handling_exceptions(self.app, conn)(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 53, in wrapped_app
    raise exc
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 42, in wrapped_app
    await app(scope, receive, sender)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/middleware/asyncexitstack.py", line 18, in __call__
    await self.app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/routing.py", line 670, in __call__
    await self.middleware_stack(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 2734, in app
    await route.handle(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/routing.py", line 455, in handle
    await self.app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/applications.py", line 1163, in __call__
    await super().__call__(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/applications.py", line 96, in __call__
    await self.middleware_stack(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/errors.py", line 186, in __call__
    raise exc
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/errors.py", line 164, in __call__
    await self.app(scope, receive, _send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/cors.py", line 96, in __call__
    await self.simple_response(scope, receive, send, request_headers=headers)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/cors.py", line 154, in simple_response
    await self.app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/middleware/exceptions.py", line 63, in __call__
    await wrap_app_handling_exceptions(self.app, conn)(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 53, in wrapped_app
    raise exc
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 42, in wrapped_app
    await app(scope, receive, sender)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/middleware/asyncexitstack.py", line 18, in __call__
    await self.app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/routing.py", line 670, in __call__
    await self.middleware_stack(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 2734, in app
    await route.handle(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 1780, in handle
    await self.original_router.handle(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 2789, in handle
    await included_router._handle_selected(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 1800, in _handle_selected
    await original_route.handle(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 1279, in handle
    await app(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 158, in app
    await wrap_app_handling_exceptions(app, request)(scope, receive, send)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 53, in wrapped_app
    raise exc
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/_exception_handler.py", line 42, in wrapped_app
    await app(scope, receive, sender)
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 144, in app
    response = await f(request)
               ^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 706, in app
    raw_response = await run_endpoint_function(
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/fastapi/routing.py", line 354, in run_endpoint_function
    return await run_in_threadpool(dependant.call, **values)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/starlette/concurrency.py", line 34, in run_in_threadpool
    return await anyio.to_thread.run_sync(func)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/anyio/to_thread.py", line 65, in run_sync
    return await get_async_backend().run_sync_in_worker_thread(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/anyio/_backends/_asyncio.py", line 2706, in run_sync_in_worker_thread
    return await future
           ^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/venv/lib/python3.11/site-packages/anyio/_backends/_asyncio.py", line 1100, in run
    result = context.run(func, *args)
             ^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/MCP/treaty_router.py", line 29, in get_treaty
    return handler.get_treaty_info(req.treaty_ref)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/MCP/treaty_mcp/handler.py", line 5, in get_treaty_info
    connection = get_db_connection()
                 ^^^^^^^^^^^^^^^^^^^
  File "/home/JarvisClaims/Musaddique/cedera/MCP/common/db.py", line 8, in get_db_connection
    return mysql.connector.connect(
           ^^^^^^^^^^^^^^^^^^^^^^^^
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
