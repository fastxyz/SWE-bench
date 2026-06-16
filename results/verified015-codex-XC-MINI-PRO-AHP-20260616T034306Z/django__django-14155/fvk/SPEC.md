# FVK Spec: ResolverMatch Partial Repr

Status: constructed, not machine-checked.

## Scope

The unit under audit is `ResolverMatch.__init__()` plus `ResolverMatch.__repr__()` in `repo/django/urls/resolvers.py`. The observable under repair is the string produced by `repr(resolve(path))` when the URL pattern's callback is a `functools.partial`.

The audited input domain is resolver-created `ResolverMatch` objects:

- `func` is any callable view object or a `functools.partial` chain wrapping such a callable.
- `args` is the tuple of URL-resolved positional arguments supplied by Django's URL pattern matchers.
- `kwargs` is the mapping of URL-resolved keyword arguments plus URL pattern defaults.
- `url_name`, app names, namespaces, route, and tried metadata are carried through unchanged except for the documented `view_name` rule.

## Public intent ledger summary

- E1/E2 require repr to reveal the wrapped callback path and partial-bound arguments for partial callbacks.
- E3 places the normalization in `ResolverMatch.__init__()`.
- E4/E5/E8 require the public runtime triple `func, args, kwargs` to remain the actual resolved callback and URL-parsed arguments.
- E6 brings nested partials into the behavior family.
- E7 supports tuple concatenation for resolver-created positional args.

See `fvk/PUBLIC_EVIDENCE_LEDGER.md` for full provenance.

## Contract

### C1 - Partial callback display path

For any partial chain `P = partial(... partial(F, PA1, PK1) ..., PAn, PKn)`, the `func=` field in `ResolverMatch.__repr__()` is the path of the unwrapped callable `F`, not `functools.partial`.

For function views, the path is `F.__module__ + "." + F.__name__`. For callable objects without `__name__`, the path is `F.__class__.__module__ + "." + F.__class__.__name__`, matching Django's existing non-partial behavior.

### C2 - Partial callback display arguments

For the same partial chain and URL-resolved `args = A`, repr displays:

- `args = PA1 + ... + PAn + A`
- `kwargs = PK1 overridden by ... overridden by PKn overridden by URL kwargs`

This captures the pre-bound partial arguments while leaving URL-resolved arguments visible.

### C3 - Non-partial frame

For a non-partial callback `F`, repr remains equivalent to the pre-fix behavior:

- `func = path(F)`
- `args = URL args`
- `kwargs = URL kwargs`

### C4 - Public dispatch frame

For all callbacks, including partials:

- `match.func` remains the original callback object supplied by the URL pattern.
- `match.args` remains the URL-resolved positional args.
- `match.kwargs` remains the URL-resolved keyword args.
- `match[0]`, `match[1]`, and `match[2]` return those same public values.

### C5 - View name frame

`view_name` remains `namespace + url_name` when `url_name` is supplied. If `url_name` is absent, `view_name` uses the same unwrapped `_func_path` used by repr.

## Formal artifacts

- Mini semantics: `fvk/mini-python-resolvermatch.k`
- K claims: `fvk/resolvermatch-spec.k`
- English paraphrase: `fvk/FORMAL_SPEC_ENGLISH.md`
- Adequacy audit: `fvk/SPEC_AUDIT.md`
- Compatibility audit: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

