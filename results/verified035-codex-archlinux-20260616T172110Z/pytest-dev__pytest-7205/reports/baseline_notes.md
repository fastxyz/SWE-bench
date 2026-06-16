# Baseline Notes

## Root cause

`--setup-show` stores the active fixture parameter on `fixturedef.cached_param`
and later prints it with `"{}".format(...)`. For a `bytes` parameter this calls
`str(bytes_value)`, which emits `BytesWarning`; under `python -bb` that warning is
promoted to an exception and aborts fixture setup.

Direct `@pytest.mark.parametrize` arguments are represented as pseudo-fixtures
during setup, so the same display path is used for the reported `data =
b"Hello World"` parameter.

## Changed files

`repo/src/_pytest/setuponly.py`

Added use of `_pytest._io.saferepr.saferepr` for cached parameter values that are
not already plain strings, and capped that representation at 42 characters. This
avoids implicit `str()` on `bytes` while keeping normal string fixture IDs and
string parameters in the existing unquoted display form.

## Assumptions and alternatives considered

I assumed the fix should be limited to how `--setup-show` formats its cached
parameter display, because parameter collection and fixture caching are already
working and the failure is raised only while writing the setup line.

I considered formatting every cached parameter with `saferepr`. That would also
fix the warning, but it would change existing string parameter and custom string
ID output from `[foo]` to `['foo']`. I rejected that broader output change because
the reported problem only requires avoiding unsafe stringification, and preserving
the existing display shape for strings is more targeted.

I also considered catching `BytesWarning` around the old formatting expression.
That would still intentionally trigger the warning path, and under `-b` it could
emit a warning before any fallback. Using `saferepr` for non-string parameters
avoids the warning-producing call instead.
