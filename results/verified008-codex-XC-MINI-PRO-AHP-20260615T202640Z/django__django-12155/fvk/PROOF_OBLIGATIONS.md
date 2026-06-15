# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Empty Input Guard

For `docstring is None` or `not docstring.strip()`, `trim_docstring()` must
return `""`.

Evidence: E10 and existing helper behavior. This prevents missing `__doc__`
values from reaching cleanup logic that expects a string.

Discharge: V1 retains the guard:

```python
if not docstring or not docstring.strip():
    return ''
```

## PO-2: First Line Excluded From Margin

For non-empty docstrings, the common indentation margin used to dedent lines
after the first line must not include the first line.

Evidence: E1-E4. The issue identifies the first line's indentation `0` as the
cause of the failure.

Discharge: V1 delegates to `inspect.cleandoc()`, modeled as the PEP 257 cleanup
algorithm per E6 and E7.

## PO-3: Empty Tail Margin Does Not Raise

For one-line docstrings or docstrings with no non-empty lines after the first
line, cleanup must not compute `min()` over an empty sequence.

Evidence: E5. The public hint reports `ValueError` for the naive patch.

Discharge: V1 removes the local `min()` calculation and delegates to
`inspect.cleandoc()` after the empty guard.

## PO-4: Directive-Safety of Cleaned Output

For a first-line-summary docstring with function-body-indented continuation
lines, the text passed to `parse_rst()` must be dedented enough that those
continuation lines are not parsed as content of the injected
`.. default-role:: cmsreference` directive.

Evidence: E1, E2, E4, E9.

Discharge: PO-2 provides the dedenting property. `parse_docstring()` already
calls `trim_docstring()` before `parse_rst()` receives title/body text.

## PO-5: Leading-Empty-Line Compatibility

Django-style docstrings whose first physical line is empty must continue to
clean to the public expected admindocs text.

Evidence: E8 and the existing PEP 257 helper comment, E7.

Discharge: `inspect.cleandoc()` implements the same intended PEP 257 cleanup
family and covers leading-empty-line docstrings.

## PO-6: API and Callsite Frame

The change must not alter the helper's call signature, return type, or
admindocs callsite protocol.

Evidence: E10 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharge: V1 changes only the implementation body and imports `cleandoc`.

## PO-7: No Loop or Recursion Obligation

`trim_docstring()` has no loop or recursive control flow after V1. The proof has
no circularity claim and no termination variant. The verification target is
partial correctness of the two branches.
