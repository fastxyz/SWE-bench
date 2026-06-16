# Intent Specification

Status: constructed from public/local evidence only. No tests, Python, K tooling, internet, hidden results, or upstream patch knowledge were used.

## Required behavior

1. When a `functools.partial` object is passed as the resolved view callback, `ResolverMatch.__repr__()` must show the wrapped view function or callable path rather than `functools.partial`.

2. For such partial callbacks, `ResolverMatch.__repr__()` must expose arguments already bound into the partial. Positional partial arguments appear before URL-resolved positional arguments. Partial keyword arguments are visible together with URL-resolved keyword arguments.

3. Nested partials are in scope because Django's public test URLconf already contains nested partial URL patterns. Their display arguments must be flattened in the same inner-to-outer order in which partial application composes, with later keyword bindings overriding earlier ones and URL-resolved keyword arguments overriding partial-bound keyword arguments.

4. For non-partial callbacks, existing `ResolverMatch.__repr__()` behavior must remain unchanged: the function path is derived from the callback function or callable object's class, and displayed args/kwargs are the URL-resolved args/kwargs.

5. The public runtime attributes `ResolverMatch.func`, `ResolverMatch.args`, and `ResolverMatch.kwargs`, and tuple unpacking of `resolve()` into `func, args, kwargs`, must remain the resolved callback and URL-parsed arguments documented by Django. Improving repr must not change request dispatch.

6. `ResolverMatch.view_name` continues to use `url_name` when supplied. When `url_name` is absent, using the unwrapped partial path is consistent with the same display-path obligation that fixes repr.

## Out of scope

1. Rewriting `URLPattern.lookup_str` is not required for this issue. It already unwraps a top-level `functools.partial`, and the reported defect is specifically `ResolverMatch.__repr__()`.

2. Manual construction of `ResolverMatch` with non-URL-shaped `args` or `kwargs` is not part of the documented `resolve()` object flow used by the issue. The audited domain is resolver-created `ResolverMatch` objects, where source patterns return tuple positional args and mapping keyword args.

