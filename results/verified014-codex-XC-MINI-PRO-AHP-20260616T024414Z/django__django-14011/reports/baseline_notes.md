# Baseline Notes

## Root cause

`LiveServerThread` uses `ThreadedWSGIServer`, which inherits `socketserver.ThreadingMixIn`. That mixin handles each request in a separate worker thread. Django's database connections are thread-local, so any database connection opened while processing a request belongs to that request thread. `LiveServerThread.run()` closes connections when the live server thread exits, but it does not close connections opened by the per-request worker threads. Those worker-thread connections can survive long enough to keep the test database open during teardown, causing intermittent failures such as "database is being accessed by other users".

## Files changed

`repo/django/core/servers/basehttp.py`

Imported `django.db.connections` and added `ThreadedWSGIServer.close_request()`. `socketserver.ThreadingMixIn.process_request_thread()` calls `shutdown_request()` after each request, and `shutdown_request()` delegates to `close_request()`. Closing all Django connections from this hook runs in the same worker thread that handled the request, so it cleans up that thread's database connections before the thread finishes.

## Assumptions and alternatives considered

I assumed the issue is specifically the lifecycle of request worker threads created by `ThreadedWSGIServer`, not the main live server thread. That matches the existing `LiveServerThread.run()` cleanup and the issue's race condition during test database teardown.

I considered changing `LiveServerThread` to use non-threaded `WSGIServer`, but rejected it because threaded request handling is intentional and existing live-server behavior depends on it for nested requests.

I considered adding cleanup to `LiveServerThread.terminate()` or `run()`, but rejected it because those methods execute in the live server thread, not in the request worker threads that own the leaked thread-local connections.

I considered changing the SQLite in-memory connection-sharing behavior mentioned in the issue notes, but rejected it as a separate concern. The minimal fix for the reported leak is to close each request thread's database connections at the request cleanup hook.

No tests or project code were run, per the benchmark instruction that this session has no execution environment.
