# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Reducible-pair shape

For any `CreateModel` operation `C` and `AlterModelOptions` operation `Aop`
where `C.name_lower == Aop.name_lower`, `C.reduce(Aop, app_label)` returns a
singleton list containing a new `CreateModel`.

Required by: I-001, E-006.

Discharged by V1: the matching branch returns `[CreateModel(...)]`.

## PO-002: Pointwise state equivalence with `AlterModelOptions.state_forwards`

Let `M = C.options`, `A = Aop.options`, and
`K = Aop.ALTER_OPTION_KEYS`. The options on the returned `CreateModel` must be
pointwise equal to the options produced by applying:

```text
model_state.options = {**M, **A}
for key in K:
    if key not in A:
        model_state.options.pop(key, default)
```

Required by: I-001 through I-004, E-001 through E-006.

Discharged by V1: lines 140-143 in `models.py` perform exactly this
merge-then-remove transformation before constructing the replacement
`CreateModel`.

## PO-003: Empty-operation clearing

When `A = {}`, every key in `K` must be absent from the returned options map,
regardless of whether it was present in `M`.

Required by: I-002, E-002.

Discharged by V1: for every iterated key, `key not in operation.options` is
true, so `options.pop(key, None)` removes the key when present and leaves the map
unchanged when absent.

## PO-004: Preservation outside `ALTER_OPTION_KEYS`

For any key `x` such that `x not in K` and `x not in dom(A)`, the returned
options map contains exactly the same binding for `x` as `M`, if one existed.

Required by: I-004, E-004, E-005.

Discharged by V1: `x` is copied by the initial merge and is never visited by the
removal loop.

## PO-005: Operation options override existing options

For any key `x in dom(A)`, including keys in `K`, the returned options map
contains `A[x]`.

Required by: I-003 and parity with `AlterModelOptions.state_forwards()`.

Discharged by V1: the initial merge lets `operation.options` override
`self.options`, and the removal loop skips keys present in `operation.options`.

## PO-006: Falsey values are preserved when explicitly provided

For any key `x in dom(A)`, if `A[x]` is falsey (`None`, `False`, empty tuple,
empty list, or empty string), the returned options map still contains `x` with
that value.

Required by: PO-005 and Django's key-presence semantics.

Discharged by V1: the condition checks `key not in operation.options`, not the
truthiness of `operation.options[key]`.

## PO-007: Frame condition for non-option attributes

The returned `CreateModel` preserves `self.name`, `self.fields`, `self.bases`,
and `self.managers`.

Required by: I-005.

Discharged by V1: the branch passes those attributes unchanged to the
replacement `CreateModel`.

## PO-008: Public compatibility and nonmatching operations

The fix must not change the public method signature, return-shape convention, or
behavior of other `CreateModel.reduce()` branches.

Required by: I-006.

Discharged by V1: only the local computation of `options` inside the existing
`AlterModelOptions` branch changed. No signature or branch predicate changed.

## PO-009: Verification honesty

The FVK proof must be labeled constructed, not machine-checked, and must not
claim test redundancy without running `kprove`.

Required by: FVK `verify.md` honesty gate and the user instruction forbidding
tests, Python execution, and K tooling.

Discharged by artifacts: `SPEC.md`, `PROOF.md`, `FINDINGS.md`, and
`ITERATION_GUIDANCE.md` all carry the constructed/not-machine-checked caveat and
recommend keeping tests.
