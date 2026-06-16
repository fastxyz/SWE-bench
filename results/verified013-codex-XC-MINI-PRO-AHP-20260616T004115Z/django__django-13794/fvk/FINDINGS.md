# FVK Findings

Status: constructed for FVK audit; not machine-checked.

## Summary

No V1-blocking defect was found. The V1 source change satisfies the public
intent for `gettext_lazy()`-style lazy strings while preserving the documented
`add` filter branch order.

## Findings

### F-001: Pre-V1 lazy right operand failure is resolved

- Classification: code bug in the baseline, resolved by V1.
- Evidence: E-1 and E-2 report that `"prefix" | add:lazyText("suffix")`
  returned `""` because `str.__add__()` rejected the `__proxy__` object.
- Input: `value = "prefix "`, `arg = lazyText("suffix")`, with neither
  resolved string integer-coercible.
- Pre-V1 observed behavior: integer coercion fails, `value + arg` raises
  `TypeError`, and the filter returns `""`.
- Expected behavior: `arg` is resolved to `"suffix"` and native string
  addition returns `"prefix suffix"`.
- V1 status: discharged by PO-2 and PO-4. Source lines
  `defaultfilters.py:678-681` resolve text promises before the original
  addition fallback at `defaultfilters.py:685-688`.

### F-002: Numeric lazy text remains governed by integer precedence

- Classification: potential regression checked and discharged.
- Evidence: E-3 and E-5 require strings coercible to integers to be summed,
  not concatenated.
- Input: `value = "1"`, `arg = lazyText("2")`.
- Expected behavior: after resolving lazy text, both operands are
  integer-coercible, so the result is `3`.
- V1 status: discharged by PO-2 and PO-3. V1 resolves text promises before the
  existing `int(value) + int(arg)` branch, so numeric lazy text follows the
  documented rule.

### F-003: Non-lazy and non-text-lazy behavior is preserved

- Classification: compatibility/frame condition checked and discharged.
- Evidence: E-4 and E-8 cover existing integer, list, tuple, date/timedelta,
  incompatible-type, and other native `+` behavior.
- Input class: operands that are not Django text promises.
- Expected behavior: the original branch order and operands are preserved.
- V1 status: discharged by PO-6. `resolve()` is identity for non-`Promise`
  values and for promises without `_delegate_text`.

### F-004: No public-intent basis for a global lazy proxy change

- Classification: alternative rejected.
- Evidence: E-1/E-2 localize the failure to the `add` filter's fallback using
  a proxy operand; E-6/E-7 identify the relevant Django text-promise family.
- Alternative considered: implement reverse-add or broader coercion in
  `django.utils.functional.lazy()`, or force every `Promise` in the filter.
- Reason rejected: a global proxy change would affect all lazy objects, and
  forcing every `Promise` could change non-text lazy values that currently
  rely on proxied-type behavior. PO-7 requires preserving public compatibility.
- V1 status: local filter-level text-promise resolution is the narrower repair.

### F-005: Proof is constructed, not machine-checked

- Classification: proof/test caveat, not a code bug.
- Evidence: FVK verify methodology and task constraints forbid running tests,
  Python, or K tooling in this environment.
- Impact: the artifacts include exact `kompile`, `kast`, and `kprove` commands,
  but no claim is machine-verified here.
- Recommendation: keep existing tests; add/retain coverage for lazy text
  concatenation and numeric lazy text. Test removal, if ever considered, must be
  conditioned on successful machine-checking.

