# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbol: `django.urls.resolvers.ResolverMatch.__init__`

- Public surface affected: computed private metadata `_func_path`, new private metadata `_func_args` and `_func_kwargs`, and derived `view_name` for unnamed partial callbacks.
- Public attributes preserved: `func`, `args`, `kwargs`, `url_name`, `route`, `tried`, `app_names`, `namespaces`, `app_name`, `namespace`.
- Callsite audit: `URLPattern.resolve()` and `URLResolver.resolve()` still pass the same callback/args/kwargs. V1 does not require caller changes.
- Override/subclass audit: no public subclass override of `ResolverMatch.__init__()` was found in source search.
- Status: compatible.

## Changed symbol: `django.urls.resolvers.ResolverMatch.__repr__`

- Public surface affected: string representation for partial callbacks.
- Intended incompatibility: `func=functools.partial` is replaced with the wrapped callable path, and displayed args/kwargs include partial-bound values.
- Public attributes and tuple unpacking: unchanged through `__getitem__()`.
- Status: compatible and intent-required.

## Request dispatch compatibility

- Public producer: `BaseHandler.resolve_request()` returns `ResolverMatch`.
- Public consumer: `_get_response()` unpacks it as `callback, callback_args, callback_kwargs`.
- V1 effect: unchanged, because `__getitem__()` still returns `(self.func, self.args, self.kwargs)`.
- Status: compatible.

## Test-file compatibility

- Existing test files were not modified.
- Existing non-partial repr expectation remains satisfied by PO-3.
- Future tests should cover partial repr, but test edits are forbidden in this task.

