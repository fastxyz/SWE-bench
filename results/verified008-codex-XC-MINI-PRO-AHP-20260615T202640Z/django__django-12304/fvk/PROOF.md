# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## What is proved

For the issue-scoped model, every choices enum class produced by
`ChoicesMeta.__new__()` carries the template do-not-call marker; Django's
existing template callable gate preserves such a class; and dotted lookup can
then resolve the requested enum member.

## Proof sketch

1. Class creation starts in `ChoicesMeta.__new__()` after enum labels and
   values have been normalized. V1 calls `super().__new__()` first, obtaining
   the actual enum class. The assignment
   `cls.do_not_call_in_templates = True` is then a post-creation class
   attribute assignment. This discharges PO-001 and preserves the member map,
   discharging PO-004.
2. Template resolution of `YearInSchool.FRESHMAN` first obtains the
   `YearInSchool` class from the context. Because classes are callable, control
   reaches the callable gate in `Variable._resolve_lookup()`.
3. The existing resolver branch checks
   `getattr(current, 'do_not_call_in_templates', False)` before attempting a
   zero-argument call. For V1 choices classes this check is true, so the branch
   executes `pass` and leaves `current` as the enum class. This discharges
   PO-002.
4. The next dotted lookup bit, `FRESHMAN`, is resolved against the preserved
   enum class, yielding the enum member. This discharges PO-003.
5. No public signature, export, resolver ordering, or choices metadata path was
   changed. This discharges PO-005.

There are no loops or recursive functions in the audited path, so no
circularity claim is required.

## Machine-check commands to run later

These commands are recorded for a future environment with K installed. They
were not executed here.

```sh
kompile fvk/mini-django-template.k --backend haskell
kast --backend haskell fvk/choices-template-spec.k
kprove fvk/choices-template-spec.k
```

Expected machine-check result after any syntax repairs required by a real K
installation: `#Top` for all claims.

## Test-redundancy recommendation

No tests were deleted or edited. If the K claims are machine-checked later,
unit tests that only assert the in-domain facts below would be logically
subsumed, but should still be kept until `kprove` returns `#Top`:

- a `TextChoices` class exposes `do_not_call_in_templates == True`;
- an `IntegerChoices` class exposes `do_not_call_in_templates == True`;
- template lookup can resolve `YearInSchool.FRESHMAN` without calling the class.

Integration tests, enum API tests, serialization tests, migration tests, and
tests for non-choices callables remain outside this issue-scoped proof and
should be kept.

## Residual risk

The proof relies on the adequacy of the mini model, which abstracts full Django
template resolution to the callable gate and dotted member lookup. The proof is
partial and constructed only; machine checking and full-language Python/K
semantics are not available in this session.
