# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Public filter registration

Obligation: `escapeseq` must be discoverable as a built-in template filter.

Evidence: ledger E1 and E7.

Discharge: `repo/django/template/defaultfilters.py` defines `escapeseq` with
`@register.filter(is_safe=True)`. `Library.filter()` stores the function by its
function name when no explicit name is passed.

Result: discharged by source inspection.

## PO-2: Per-element sequence mapping

Obligation: for every finite sequence `xs`, `escapeseq(xs)` returns a sequence
with the same order and length, where each result element corresponds to exactly
one input element.

Evidence: ledger E2, E3, and E5.

Discharge: V1 code returns `[conditional_escape(obj) for obj in value]`. Python
list-comprehension semantics traverse the input iterable in order and produce
one output element for each input element. The K claim `ESCAPESEQ-MAP` models
this as `escapeSeq(I ; REST) = conditionalEscape(I) ; escapeSeq(REST)`.

Result: discharged by source inspection and constructed proof.

## PO-3: Escape semantics, not force-escape semantics

Obligation: unsafe values are escaped; already-safe values are not double
escaped.

Evidence: ledger E3 and E4.

Discharge: V1 uses `conditional_escape()`, the same helper used by the existing
`escape` filter. The K model has `conditionalEscape(raw(S)) =
safe(htmlEscape(S))` and `conditionalEscape(safe(S)) = safe(S)`.

Result: discharged, with `conditional_escape()` treated as trusted existing
Django behavior.

## PO-4: Correct `autoescape off` composition with `join`

Obligation: in `{{ some_list|escapeseq|join:"," }}` with autoescape disabled,
each item is escaped before `join` concatenates the sequence.

Evidence: ledger E2 and E6.

Discharge: `escapeseq` transforms the sequence before the `join` filter runs.
In `autoescape=False`, `join` uses `arg.join(value)`, so the only point where
item escaping can occur is the preceding filter. The K claim
`ESCAPESEQ-JOIN-OFF` models `joinOff(escapeseq(L), SEP)` reaching
`safe(joinSafe(escapeSeq(L), SEP))`.

Result: discharged by source inspection and constructed proof.

## PO-5: No unintended separator or existing-filter changes

Obligation: the fix must not alter existing `join`, `escape`, `safe`, or
`safeseq` behavior.

Evidence: ledger E6 and public compatibility audit.

Discharge: V2 does not edit these functions. Separator handling remains in
`join`; `escapeseq` only prepares sequence items.

Result: discharged by diff inspection.

## PO-6: Public documentation

Obligation: because the change adds a public built-in template filter, the
built-in filter reference should document it.

Evidence: ledger E8 and public compatibility audit.

Discharge: V2 adds `.. templatefilter:: escapeseq` to
`repo/docs/ref/templates/builtins.txt` with the `autoescape off` usage pattern.

Result: discharged after V2 docs edit.

## PO-7: Honesty gate

Obligation: do not claim machine verification or remove tests unless the K
commands have actually run and returned `#Top`.

Evidence: FVK `verify.md` honesty gate.

Discharge: no tests or K commands were run. `PROOF.md` includes the exact
commands and labels the proof constructed, not machine-checked.

Result: discharged as an audit-process obligation.
