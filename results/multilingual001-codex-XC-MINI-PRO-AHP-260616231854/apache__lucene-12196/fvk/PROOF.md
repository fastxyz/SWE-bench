# Constructed Proof

Status: constructed, not machine-checked. No tests, project code, Python, `kompile`, or `kprove`
were run.

## Claims Proved On Paper

The K artifacts are:

- `fvk/mini-queryparser.k`
- `fvk/multifield-queryparser-spec.k`

The relevant claims are the direct phrase, direct multi-phrase, boosted phrase, boosted
multi-phrase, boosted non-phrase, and null cases in `multifield-queryparser-spec.k`.

## Proof Sketch

The proof is by structural induction on the finite query wrapper shape handled by `applySlop`.

Base case, `nullQuery`: the mini semantics rewrites `applySlop(nullQuery, S)` to `nullQuery`. This
matches PO-006 and preserves Java's existing `instanceof` behavior on null.

Base case, `other(P)`: the mini semantics rewrites `applySlop(other(P), S)` to `other(P)`. This
matches PO-006: non-phrase queries are outside the slop-setting family and are unchanged.

Base case, `phrase(P, OLD)`: the mini semantics rewrites `applySlop(phrase(P, OLD), S)` to
`phrase(P, S)`. The payload `P` is preserved and only the slop changes, discharging PO-001 and
PO-004.

Base case, `multiPhrase(P, OLD)`: the mini semantics rewrites `applySlop(multiPhrase(P, OLD), S)` to
`multiPhrase(P, S)`. The payload `P` is preserved and the requested slop is reflected, discharging
PO-002 and PO-004.

Inductive case, `boost(Q, B)`: the mini semantics performs one genuine rewrite step from
`applySlop(boost(Q, B), S)` to `applySlop(Q, S) ~> reboost(B)`. By the induction hypothesis,
`applySlop(Q, S)` reaches the correct slop-adjusted form for `Q`. The continuation rule then rewrites
`Q' ~> reboost(B)` to `boost(Q', B)`. This discharges PO-003 and preserves the exact boost value.
The model separates query values from `applySlop` expressions so the continuation can rewrap only
after the inner slop expression has reduced to a query value.

Parser composition: in the source, the multi-field quoted path constructs a per-field query, wraps it
in `BoostQuery` when a field boost exists, and then calls `applySlop`. By PO-003, the helper turns
`BoostQuery(Q, B)` into `BoostQuery(applySlop(Q, S), B)`. Therefore the issue's boosted phrase case
has both the slop and the boost, discharging PO-005.

Compatibility: V1 changes only the private helper body and leaves public constructors, protected
method signatures, and parser call shapes untouched. This discharges PO-008.

## Adequacy Check

The formal claims say exactly the public intent requires for this issue: a field boost must not hide
the phrase query from slop application. The claims do not prove or depend on the legacy output where
slop is missing; that legacy output is Finding F-001.

The abstraction is adequate for the defect because it keeps slop, boost, and phrase payload as
distinct observables. A failing pre-V1 instance maps to `boost(phrase(P, OLD), B)` while the passing
instance maps to `boost(phrase(P, S), B)`, so the model can distinguish the bug from the fix.

## Machine Check Commands Not Run

These commands are the intended later machine-check steps. They were not executed in this benchmark
session.

```sh
kompile fvk/mini-queryparser.k --backend haskell
kast --backend haskell fvk/multifield-queryparser-spec.k
kprove fvk/multifield-queryparser-spec.k
```

Expected result after a successful machine check: `kprove` reduces the claims to `#Top`.

## Test Redundancy

No test deletion is recommended. The proof is constructed but not machine-checked, and the benchmark
forbids modifying tests. Useful tests to add in a normal development setting are listed in
`ITERATION_GUIDANCE.md`, but no test files were changed here.
