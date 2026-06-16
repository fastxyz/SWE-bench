# Public Compatibility Audit

No public API compatibility issue was found.

The V1 patch changes no function or method signatures. The return tuple shape of
all edited `get_prefetch_queryset()` implementations remains unchanged.

The patch changes no query filter, manager protocol, descriptor name, cache key
name, or public import. No public callsite or subclass override needs an update.

No test files were modified.

