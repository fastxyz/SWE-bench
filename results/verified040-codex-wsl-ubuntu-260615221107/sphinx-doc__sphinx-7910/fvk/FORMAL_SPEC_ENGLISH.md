# Formal Spec English

The K artifacts are constructed, not machine-checked.

Claim C1, decorated method init: for a class member named `__init__` with a
docstring, when module+qualname resolution finds an owner defining that member
and `napoleon_include_init_with_doc` is true, `_skip_member()` returns `False`
even if the wrapper globals do not contain the class.

Claim C2, decorated class init: for a class member named `__init__` with a
docstring, when module+qualname resolution finds a wrapper class whose
`__wrapped__` original defines that member and the init include setting is true,
`_skip_member()` returns `False`.

Claim C3, nested/private owner: for class or exception members with dotted owner
paths, module+qualname resolution remains sufficient to establish ownership, and
the private include setting can force include documented private members.

Claim C4, top-level fallback: if module+qualname resolution fails for a
top-level owner but the old `obj.__globals__[cls_path]` path finds the owner,
the previous force-include behavior is preserved.

Claim C5, no owner: if class ownership is not established for a class or
exception member, `_skip_member()` returns `None`.

Claim C6, config gate: if the relevant Napoleon include-with-doc setting is
false, ownership and a docstring are not enough; `_skip_member()` returns
`None`.

Claim C7, module private: module-level private or special members with
docstrings are governed by the include settings and do not depend on class owner
resolution.

Claim C8, weakref: `__weakref__` is never force-included by this hook.
