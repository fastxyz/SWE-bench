# ITERATION GUIDANCE

Status: V1 stands unchanged after FVK audit.

## Decision

Do not edit Django source beyond V1. The FVK spec and proof obligations identify one real code bug, F1, and V1 discharges it by changing only the redirect target from `request.path_info + "/"` to `request.path + "/"`.

## Guidance for a Future Code Pass

1. Keep `resolve()` on `request.path_info + "/"`. Moving resolver lookup to `request.path + "/"` would violate PO-2.
2. Keep the successful redirect on `request.path + "/"`. Reverting to `request.path_info + "/"` would violate PO-1 and reproduce F1.
3. Do not switch to `request.get_full_path(force_append_slash=True)` without a separate public requirement. Query-string preservation is outside this issue's stated target and is recorded in F3.
4. Do not change `catch_all_view()`'s signature, decorator, wrapper path, or exception behavior. PO-4 depends on preserving that public compatibility.

## Suggested Public Tests

Do not edit tests in this benchmark. In an ordinary development setting, add a regression test for:

- `FORCE_SCRIPT_NAME="/script"`, a valid admin URL missing its trailing slash, `APPEND_SLASH=True`, authenticated staff request.
- Expected response: permanent redirect to `"/script/<admin path>/"`.

Keep broader admin URL, authentication, and request-construction tests because the constructed proof covers only the local catch-all branch behavior.
