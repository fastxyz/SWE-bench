# FVK Spec

Status: constructed for FVK audit; not machine-checked.

## Unit Under Audit

`django.template.defaultfilters.add(value, arg)` in
`repo/django/template/defaultfilters.py`.

## Human-Readable Contract

Let `resolve(x)` be:

- `str(x)` if `x` is a Django `Promise` and its proxy is marked as text with
  `_delegate_text`;
- `x` otherwise.

For any inputs `value` and `arg`, define `v = resolve(value)` and
`a = resolve(arg)`. The filter must return:

1. `int(v) + int(a)` if both integer coercions succeed;
2. otherwise `v + a` if Python native addition succeeds;
3. otherwise `""`.

This is a partial-correctness contract over the filter's return value. There
are no loops or recursive calls in the audited function.

## Public Intent Ledger Summary

- E-1/E-2 require a normal string plus a lazy text proxy to concatenate after
  lazy resolution rather than falling through to `""`.
- E-3/E-5 require integer coercion to remain first, including for numeric lazy
  text.
- E-4 requires the original native-addition and empty-string fallback ordering.
- E-6/E-7 justify `Promise` plus `_delegate_text` as the Django-specific lazy
  text detector for `gettext_lazy()`.
- E-8 requires non-lazy add behavior to remain unchanged.

## Formalization Scope

The accompanying K files model only the fragment needed for this filter:

- values, text promises, integer coercion success/failure;
- native Python `+` success/failure;
- the final empty-string fallback.

The model intentionally does not attempt a full Python exception semantics.
Instead, `intable(V)` and `plusable(V, A)` represent whether `int()` and native
`+` would succeed for the resolved operands. This abstraction is
property-complete for the defect because it distinguishes:

- failing pre-V1 case: `plusable(String, lazyText(String))` is not reached as
  string-plus-string because the right operand remains a proxy;
- passing V1 case: `resolve(lazyText(T)) = T`, so `plusable(String, String)`
  and `plusResult(String, String)` apply.

## Frame Conditions

- The filter signature and template registration remain unchanged.
- Non-`Promise` operands are unchanged by `resolve()`.
- Non-text promises are not forced by this fix; their existing proxied-type
  behavior is left to the original `int()` / `+` paths.
- No test files are modified.

