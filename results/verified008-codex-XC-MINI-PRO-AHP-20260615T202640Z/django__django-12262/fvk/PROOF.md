# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run in this environment.

## Claims

The formal claims are in `fvk/template-tag-parse-bits-spec.k` and are supported
by the abstract parser-state semantics in `fvk/mini-python.k`.

- `ALLOW-DEFAULT-KWONLY` proves PO-1.
- `DUPLICATE-KWONLY` proves PO-2.
- `UNKNOWN-STILL-UNEXPECTED` proves PO-3.
- `MISSING-REQUIRED-KWONLY` proves PO-4.

PO-5 is discharged by public compatibility inspection: all callers still call
`parse_bits()` with the same signature.

## Proof Sketch

### PO-1: Optional Keyword-Only Parameters Are Legal

Start from a parsed keyword token `param=value` where `param in kwonly`,
`param not in kwargs`, and `varkw is None`.

V1 executes the keyword branch in `parse_bits()`:

```python
if param in kwargs:
    ...
elif param not in params and param not in kwonly and varkw is None:
    ...
else:
    kwargs[str(param)] = value
```

The duplicate branch is false because `param not in kwargs`. The unexpected
branch is false because `param in kwonly`. Therefore the only reachable branch
is the `else` branch, which records the keyword. The fact that `param` is absent
from `unhandled_kwargs` because it has a default is no longer relevant to
legality. This discharges PO-1.

### PO-2: Duplicate Keyword Names Take Precedence

Start from two keyword tokens with the same name `param`, where `param in
kwonly`.

For the first token, `param not in kwargs` and `param in kwonly`, so PO-1's
argument records `param` in `kwargs`. If it was required keyword-only, it is also
removed from `unhandled_kwargs`.

For the second token, the first V1 branch checks `param in kwargs` before any
unexpected-keyword predicate. That branch raises the "multiple values for
keyword argument" `TemplateSyntaxError`. The old failure path, where the second
token was no longer in `unhandled_kwargs` and was therefore called unexpected,
is unreachable because `unhandled_kwargs` is no longer used for legality and
the duplicate branch has priority. This discharges PO-2.

### PO-3: Unknown Keywords Stay Unexpected

Start from a keyword token `param=value` where `param not in params`, `param not
in kwonly`, `varkw is None`, and `param not in kwargs`.

The duplicate branch is false. The unexpected branch condition is true exactly
for this shape, so `parse_bits()` raises the existing unexpected-keyword
`TemplateSyntaxError`. The V1 change does not legalize unknown names. This
discharges PO-3.

### PO-4: Missing Required Keyword-Only Parameters Stay Missing

`unhandled_kwargs` is still initialized to the keyword-only parameters without
defaults:

```python
unhandled_kwargs = [
    kwarg for kwarg in kwonly
    if not kwonly_defaults or kwarg not in kwonly_defaults
]
```

The V1 edit does not change that initialization or the final missing-argument
check. A required keyword-only parameter remains in `unhandled_kwargs` unless a
valid keyword token supplies it. At end of parsing, any remaining name in
`unhandled_kwargs` triggers the existing missing-argument `TemplateSyntaxError`.
This discharges PO-4.

### PO-5: Shared Helper Compatibility

`Library.simple_tag()`, `Library.inclusion_tag()`, and
`InclusionAdminNode.__init__()` all pass `kwonly` and `kwonly_defaults` into
`parse_bits()`. V1 changes no function signatures and no return shape. The same
proved helper behavior reaches both helpers named by the issue. This discharges
PO-5.

## Adequacy Check

The English meaning of the K claims is recorded in `FORMAL_SPEC_ENGLISH.md`.
`SPEC_AUDIT.md` compares those claims against `INTENT_SPEC.md`; all obligations
needed for django__django-12262 pass. PO-6 is intentionally unclaimed because it
is adjacent to, but not required by, the reported issue.

## Machine-Check Commands

These commands are emitted for a later environment with K installed. They were
not run here.

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell template-tag-parse-bits-spec.k
kprove template-tag-parse-bits-spec.k
```

Expected machine-check result in a K environment compatible with this minimal
semantics: `#Top` for the four claims.

## Test Redundancy Recommendation

Recommendation only, conditioned on machine-checking. Do not delete tests in
this task.

After `kprove` returns `#Top`, point tests that assert PO-1 through PO-4 for
specific in-domain keyword-only cases would be subsumed by the proof. Integration
tests, rendering tests, out-of-domain diagnostics, and the adjacent PO-6 case
should be kept.
