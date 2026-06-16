# FVK Findings

Status: constructed, not machine-checked. Findings are based on public issue text and static source inspection only.

## F-001: Missing construction-path value for `polylog(2, 1/2)`

Input: `polylog(2, Rational(1, 2))`.

Observed before the fix: the issue shows the object remaining as `polylog(2, 1/2)`.

Expected: `pi**2/12 - log(2)**2/2`.

Classification: code bug.

Resolution: V1 added `elif s == 2 and z == S.Half: return pi**2/12 - log(2)**2/2` in `polylog.eval`. This remains in V2.

Proof obligation: PO-001.

## F-002: Incorrect polar factor in `polylog(1, z)` expansion

Input: `expand_func(polylog(1, z))`.

Observed before the fix: the issue shows `-log(z*exp_polar(-I*pi) + 1)`.

Expected: `-log(1 - z)`.

Classification: code bug and symbolic simplification blocker.

Resolution: V1 changed the order-one expansion to `-log(1 - z)`. This remains in V2.

Proof obligation: PO-002.

## F-003: V1 introduced a private-method compatibility hazard in `lerchphi`

Input class: `lerchphi` rational-`a` expansion paths that construct a `polylog` subterm which now evaluates immediately, for example a symbolic path whose subterm is `polylog(2, S.Half)`.

Observed by static inspection of V1: `lerchphi._eval_expand_func` called `polylog(...)._eval_expand_func(**hints)` directly. After F-001, `polylog(2, S.Half)` can be an `Add`, not a `polylog` object. `Add` does not define the private polylog expansion method.

Expected: the caller should use the public expression-level `expand_func(...)` helper, which accepts already-evaluated expressions and unevaluated function objects.

Classification: code bug introduced by a correct V1 placement decision.

Resolution: V2 changed the call to `expand_func(polylog(s, zet**k*root), deep=False)`.

Proof obligation: PO-003.

## F-004: Existing public tests/comments encode legacy behavior

Input: the public test assertion expecting `-log(1 + exp_polar(-I*pi)*z)` and the Wester XFAIL comment saying the `1/2` value is not known.

Observed: these public artifacts conflict with the issue's requested behavior.

Expected: treat them as SUSPECT evidence under FVK. They should not veto the issue-derived specification.

Classification: stale public-test evidence.

Resolution: no test files were modified, per task instructions. The production fix follows the issue-derived spec.

Proof obligations: PO-001, PO-002, PO-005.

## F-005: Special-value family completeness

Input family: automatic `polylog` values around the issue's concrete order-two value.

Observed: existing code already evaluates `z = 0`, `z = 1`, and `z = -1` for all orders. V1 adds the derivable missing member `polylog(2, 1/2)`.

Expected: no additional construction-path members are forced by the issue text or by the local docstring. Symbolic identities for order `1`, order `0`, and negative integer orders remain opt-in `expand_func` behavior.

Classification: audited and no further code change required.

Resolution: V2 keeps V1's placement for the concrete value and does not broaden automatic evaluation beyond the proven member.

Proof obligation: PO-004.

## F-006: Proof status is constructed only

Input: the FVK formal claims in `fvk/polylog-spec.k`.

Observed: benchmark instructions forbid running K tooling.

Expected: record exact commands but do not claim machine verification.

Classification: proof-honesty requirement.

Resolution: `PROOF.md` includes the commands and labels the proof constructed, not machine-checked.

Proof obligation: PO-005.
