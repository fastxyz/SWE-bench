# Intent Spec

Status: constructed from public evidence only.

1. When `napoleon_include_init_with_doc` is true, a documented `__init__`
   member of a documented class or exception is in scope for force-inclusion.
2. Decorating `__init__` with `functools.wraps()` must not stop that member
   from being recognized as the class member when the wrapper retains the
   original `__doc__`, `__module__`, and `__qualname__`.
3. The owner lookup must not depend solely on the wrapper function's
   `__globals__`, because a decorator defined in another module has globals
   from the decorator module rather than the documented class module.
4. Existing nested-class support must be preserved: dotted class paths derived
   from `__qualname__` are resolved by walking attributes from `obj.__module__`.
5. Existing include-with-doc settings still gate the override:
   `napoleon_include_init_with_doc`,
   `napoleon_include_private_with_doc`, and
   `napoleon_include_special_with_doc`.
6. Module-level private and special members with docstrings keep the existing
   Napoleon behavior, independent of class ownership.
7. The public hint that class decoration has the same issue means a class
   wrapper using the standard `__wrapped__` convention should not hide ownership
   of a documented member from Napoleon.
8. If ownership cannot be established, `_skip_member()` must return `None` and
   leave autodoc's default skip decision unchanged.
