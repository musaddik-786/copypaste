(venv) JarvisClaims@JarvisClaims:~/Musaddique/cedera/MCP$ python3 main.py 
INFO:     Started server process [16021]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:7720 (Press CTRL+C to quit)
INFO:     127.0.0.1:40648 - "GET /docs HTTP/1.1" 200 OK
INFO:     127.0.0.1:40648 - "GET /openapi.json HTTP/1.1" 200 OK
INFO:     127.0.0.1:40636 - "GET /api/v1/treaty_management_mcp/docs HTTP/1.1" 200 OK
INFO:     127.0.0.1:40636 - "GET /api/v1/treaty_management_mcp/openapi.json HTTP/1.1" 200 OK
INFO:     127.0.0.1:40664 - "POST /api/v1/treaty_management_mcp/treaty_management_mcp HTTP/1.1" 500 Internal Server Error
ERROR:    Exception in ASGI application
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
           ^^^^^^^
NameError: name 'handler' is not defined









    main.py
    
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi_mcp import FastApiMCP

# from init_db import init_db

# from voice_text_intake_router import router as voice_text_intake_router
# from duplicate_check_router import router as duplicate_check_router
# from segmentation_router import router as segmentation_router
# from claim_status_router import router as claim_status_router
from treaty_router import router as treaty_router
# from feedback_router import router as feedback_router
# from policy_coverage_router import router as policy_coverage_router
# from claim_readiness_router import router as claim_readiness_router
# from communication_router import router as communication_router

import uvicorn



app = FastAPI(docs_url="/docs", title = "Cedera")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def _make_cors_app(title: str, description: str = "") -> FastAPI:
    sub = FastAPI(title=title, description=description)
    sub.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    return sub

treaty_app = _make_cors_app(
    title = "treaty management agent",
    description="mcp tools for treaty management",
)

treaty_app.include_router(treaty_router)
FastApiMCP(
    treaty_app,
    include_operations=[
        "treaty_management_mcp",
    ],
).mount_http()
app.mount("/api/v1/treaty_management_mcp", treaty_app)




@app.get("/health")
def health_check():
    return{
        "status" : "healthy",
        "service" : "cedera"
    }


# @app.on_event("startup")
# def startup():
    # init_db()


if __name__ == "__main__":

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=7720
    )


    we dont need init db we already created the tables

    Curl

curl -X 'POST' \
  'http://localhost:7720/api/v1/treaty_management_mcp/treaty_management_mcp' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "treaty_ref": "TRT-2026-001"
}'
Request URL
http://localhost:7720/api/v1/treaty_management_mcp/treaty_management_mcp
Server response
Code	Details
500
Undocumented
Error: Internal Server Error

Response body
Download
Internal Server Error
Response headers
 access-control-allow-origin: * 
 content-length: 21 
 content-type: text/plain; charset=utf-8 
 date: Sat,12 Sep 2026 10:02:17 GMT 
 server: uvicorn 
