# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "`napoleon_include_init_with_doc = True`, so `__init__` will be documented" | A documented init is force-included when the init include setting is enabled. | Encoded in claims C1, C2, C6. |
| I2 | prompt | "I decorate it with `functools.wraps`, so the decorated object still has the same `__doc__`." | A wrapped callable with preserved metadata remains in the intended domain. | Encoded in C1. |
| I3 | prompt | "`obj.__globals__` does not contain the class anymore" | Owner recognition must not rely only on wrapper globals. | Encoded in C1. |
| I4 | source | Pre-V1 code already used `importlib.import_module(obj.__module__)` plus dotted `getattr` for nested class paths. | Preserve module+qualname nested resolution. | Encoded in C3. |
| I5 | source/docstring | `_skip_member` returns `False` to include and `None` to keep default behavior. | Non-owned or unconfigured members must not be force-included. | Encoded in C5, C6, C8. |
| I6 | public tests/source | Existing tests cover private/special/module include settings and `__weakref__` exclusion. | Keep config and weakref gates unchanged. | Encoded in C6, C7, C8. |
| I7 | prompt hint | "I've found the same issue if you decorate the class as well." | Standard class wrappers that expose `__wrapped__` should be checked as owner candidates. | Encoded in C2. |
| I8 | compatibility | `_skip_member` is connected to `autodoc-skip-member`; no public signature change is requested. | Preserve callback signature and return protocol. | Encoded in compatibility audit. |
