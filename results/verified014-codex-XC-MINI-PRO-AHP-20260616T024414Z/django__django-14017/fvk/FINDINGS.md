# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix `Q` rejected a valid conditional expression

- Classification: code bug, fixed by V1.
- Evidence: E1, E2, E3, PO-1, PO-3.
- Input: `Q() & Exists(Product.objects.all())`.
- Pre-fix observed behavior: `TypeError(<Exists object>)` from
  `Q._combine()` because `other` was not an instance of `Q`.
- Expected behavior: a `Q` object containing the `Exists` condition, with no
  `TypeError`.
- V1 status: discharged. `Q._combine()` now checks `other.conditional` and
  wraps accepted non-`Q` operands as `Q(other)`.

## F2: Empty-left-`Q` combination needs expression-safe deconstruction

- Classification: proof-derived edge case, fixed by V1.
- Evidence: E1, PO-5, PO-7.
- Input: `Q() & Exists(Product.objects.all())`.
- V1 audit observation: after wrapping `Exists` as `Q(Exists(...))`, the
  existing empty-`self` branch clones `other` through `other.deconstruct()`.
- Expected behavior: deconstruction returns positional args for the expression
  child so reconstruction yields `Q(Exists(...))`.
- V1 status: discharged. `Q.deconstruct()` now treats a single non-tuple child
  as a positional arg instead of indexing it as a lookup tuple.

## F3: Non-conditional operands remain rejected

- Classification: compatibility check, confirmed by V1.
- Evidence: E7, PO-2.
- Input: `Q(x=1) & object()`.
- Expected behavior: `TypeError(object)`.
- V1 status: discharged. Plain objects have no truthy `conditional` attribute,
  so `_combine()` raises `TypeError(other)` before wrapping.

## F4: V1 does not need another source edit under the audited contract

- Classification: confirmation.
- Evidence: PO-1 through PO-9.
- Input family: `Q()` or non-empty `Q(...)` combined with `Exists(...)` by `&`
  or `|`, plus existing non-conditional object rejection.
- Expected behavior: valid `Q`/`Exists` pairs produce a `Q`; non-conditional
  objects raise `TypeError`.
- V1 status: all proof obligations are satisfied by the current source. No V2
  source edit is justified by public intent.

## Residual risk

The proof is constructed over a mini semantics and was not machine-checked with
K. The audited domain is Django conditional expressions such as `Exists`, not
arbitrary user objects that only define a `conditional` attribute.

