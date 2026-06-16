# FVK Findings

Status: constructed from public evidence, not machine-checked.

## F-001: V1 bypassed inherited non-false reductions

- Classification: code robustness bug in the V1 fix.
- Evidence: `Operation.reduce()` has generic elidable behavior and `ModelOptionOperation.reduce()` has same-option/delete behavior. `PROOF_OBLIGATIONS.md` PO-1 requires the new override to preserve inherited non-`False` results.
- Input: `self = U("Book", set())`, `operation = I("Book", set())` where `operation.elidable` or another inherited rule would make `super().reduce(operation, app_label)` return a non-`False` result.
- Observed in V1: the override checked the cross together-option case first and returned `True`.
- Expected: return the inherited non-`False` result, e.g. `[self]` for an elidable `operation`.
- Resolution: fixed in V2 by assigning `result = super().reduce(operation, app_label)`, returning it when `result is not False`, and only then applying the cross-option transparency rule.
- Related obligations: PO-1, PO-2.

## F-002: Original optimizer could not collapse split together-option remove/add operations

- Classification: original code bug described by the public issue.
- Evidence: the issue's example says `[U(m,set()), I(m,set()), U(m,{col}), I(m,{col})]` should optimize to `[U(m,{col}), I(m,{col})]`.
- Input: `U0 = U("mymodel", set())`, `I0 = I("mymodel", set())`, `U1 = U("mymodel", {("col",)})`, `I1 = I("mymodel", {("col",)})`.
- Observed before the fix: `U0.reduce(I0)` and `I0.reduce(U1)` were same-model boundaries because the operations were different concrete classes. The optimizer could not move the same-option pairs together, so the four operations remained.
- Expected: `U0` and `I0` are removable because the later `U1` and `I1` set the final unique/index-together values and no field operation intervenes.
- Resolution: fixed by PO-2 and PO-4. Different together options on the same model return `True` after inherited reductions fail.
- Related obligations: PO-2, PO-3, PO-4, PO-6.

## F-003: Field-operation boundaries must not be optimized away

- Classification: regression risk checked by proof obligations.
- Evidence: the issue explains that split removal/addition exists so "field alterations work as expected during in between operations."
- Input: `U0 = U("Book", set())`, `F = F("Book", "author")`, `U1 = U("Book", {("author",)})`.
- Expected: `U0` must not collapse across `F` when `F` references a field used by the later together option.
- Resolution: V2 preserves this because the new `True` case only applies when `operation` is another `AlterTogetherOptionOperation`; field operations still use inherited `references_model()` / `references_field()` boundary behavior.
- Related obligations: PO-5.

## F-004: Proof is constructed, not machine-checked

- Classification: proof capability / environment gap.
- Evidence: the task forbids running tests, Python, or K tooling.
- Impact: The artifacts include commands and expected `#Top` outcomes, but no machine result is claimed. No test deletion is recommended without later machine checking.
- Resolution: No production code change. Keep tests; run the emitted commands only in an environment where K tooling is allowed.
- Related obligations: PO-7.
