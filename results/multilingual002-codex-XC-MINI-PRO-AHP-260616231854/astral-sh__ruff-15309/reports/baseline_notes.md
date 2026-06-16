# Baseline Notes

## Root cause

The F523 checker correctly identifies unused positional arguments in `str.format`
calls, but its autofix always routes through the generic CST argument-removal
helper. When every positional argument is removed and there are no keyword
arguments, that helper rewrites `"Hello".format("world")` as
`"Hello".format()` instead of removing the now-empty `.format(...)` call.

## Files changed

- `repo/crates/ruff_linter/src/rules/pyflakes/fixes.rs`: Added a special case to
  `remove_unused_positional_arguments_from_format_call`. If all explicit
  positional arguments are being removed and the call has no keyword arguments,
  the fix now replaces the full `.format(...)` call expression with the source
  text for the attribute receiver. This turns `"Hello".format("world")` into
  `"Hello"` while preserving the existing argument-removal path for calls that
  still have arguments afterward.

## Assumptions and alternatives considered

- I assumed the special case should only apply when the resulting call would be
  empty. Calls with remaining keyword arguments, including `**kwargs`, continue
  to use the existing `.format(...)` rewrite path because removing the full call
  would also drop potentially meaningful arguments.
- I considered changing the checker to pass more context or to suppress the fix
  in this case, but the bug is in fix construction rather than detection.
  Updating the existing fix helper keeps the change local to source rewriting.
- I considered extending or replacing the CST transform to emit the receiver
  expression, but a direct range replacement is simpler here: the checker only
  invokes this helper for `.format` calls on string literals, and the AST already
  exposes the receiver range.
