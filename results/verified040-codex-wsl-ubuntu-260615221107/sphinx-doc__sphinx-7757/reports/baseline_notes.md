# Baseline Notes

## Root Cause

`sphinx.domains.python._parse_arglist()` parses a documented Python signature by
calling `sphinx.util.inspect.signature_from_str()`, then renders each resulting
`inspect.Parameter`.

For Python 3.8 positional-only syntax, the AST stores positional defaults in
`arguments.defaults` across the combined positional list:

```text
posonlyargs + args
```

The previous `signature_from_str()` implementation only applied defaults while
iterating `args.args`. Positional-only parameters were created without a
`default`, so a signature such as `foo(a, b=0, /, c=1)` lost `b=0` before the
Python domain renderer saw it.

## Files Changed

`repo/sphinx/util/inspect.py`

Updated `signature_from_str()` to pad `args.defaults` against the full positional
parameter list, including `posonlyargs`, before creating `inspect.Parameter`
objects. The same aligned defaults list is now used for positional-only and
positional-or-keyword parameters, preserving defaults such as `b=0` in
`foo(a, b=0, /, c=1)`.

## Assumptions

The intended behavior is that manually documented Python signatures should show
defaults for positional-only parameters exactly as they already do for regular
positional-or-keyword parameters.

I assumed the fix belongs in `signature_from_str()` rather than in
`sphinx.domains.python._parse_arglist()`, because the default is already missing
from the intermediate `inspect.Signature`. Fixing the parser helper preserves
the existing rendering path and also keeps `signature_from_str()` accurate for
other callers.

I considered special-casing `/` handling in the Python domain renderer, but
rejected it because `/` insertion is already correct. The issue is not placement
of the positional-only separator; it is loss of default metadata while converting
from AST arguments to `inspect.Parameter` instances.
