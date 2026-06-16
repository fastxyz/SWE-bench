# Baseline Notes

## Root cause

`django.utils.autoreload.get_child_arguments()` rebuilt child-process arguments
for any `python -m ...` invocation from `__main__.__spec__.parent`. That is
correct for package entry points such as `python -m django`, where the executed
module is `django.__main__` and the restart command should be `python -m django`.
It is incorrect for ordinary module files such as `python -m foo.bar.manage`,
where `__spec__.name` is `foo.bar.manage` and `__spec__.parent` is only
`foo.bar`. The autoreloader therefore restarted the process with the final module
component dropped.

## Files changed

`repo/django/utils/autoreload.py`

Updated `get_child_arguments()` so it derives the `-m` target from
`__main__.__spec__.name`. It now uses `__spec__.parent` only when the spec name is
exactly `__main__` or ends with `.__main__`, preserving the existing package
entry-point behavior while keeping full dotted module names intact. If the spec
does not yield a usable module name, the existing script-path fallback remains in
place.

## Assumptions and alternatives considered

I assumed the intended restart command should mirror Python's original `-m`
target: package `__main__` executions restart with the package name, while module
file executions restart with the full module name.

I considered continuing to use `__spec__.parent` for all `-m` invocations, but
that is the source of the reported truncation for dotted modules. I also
considered identifying package entry points by checking only the last dotted
component after splitting the name, but that would treat module names such as
`foo.my__main__` incorrectly. Checking for exact `__main__` or the `.__main__`
suffix matches the package-entry-point case more precisely.
