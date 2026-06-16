# Public Compatibility Audit

Status: constructed for audit; not machine-checked.

## Changed Symbol

`sphinx.util.inspect.signature_from_str(signature: str) -> inspect.Signature`

Compatibility result: compatible.

Reason:

- The function name, parameters, return type, and exception path for invalid
  parser input are unchanged.
- Source callsites continue to pass a single string argument.
- The return shape is still an `inspect.Signature` containing
  `inspect.Parameter` objects.
- The only changed field is the previously missing `default` value on
  positional-only `Parameter` objects.

## Observable Consumer

`sphinx.domains.python._parse_arglist(arglist: str) -> desc_parameterlist`

Compatibility result: compatible.

Reason:

- Its public signature is unchanged.
- It already rendered defaults whenever `param.default is not param.empty`.
- Its `/` insertion logic is unchanged and still depends on `Parameter.kind`.

## Callsite Search Summary

Static source search found `signature_from_str()` imported by
`sphinx.domains.python` and visible public tests. No production callsite requires
the old missing-default behavior.

## Test Handling

No test files were modified. Any test-removal recommendation is conditioned on a
future real `kprove` run returning `#Top`; this audit makes no such deletion.
