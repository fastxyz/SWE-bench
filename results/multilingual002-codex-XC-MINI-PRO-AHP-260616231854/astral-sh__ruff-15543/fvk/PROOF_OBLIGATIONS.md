# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Reported singleton bare tuple

- Claim: `fix(iter(bareTuple, "x,")) => "yield from (x,)"`
- Intent evidence: `SPEC.md` E1-E3.
- Source evidence: V1 wraps `Expr::Tuple { parenthesized: false, .. }` before the final `yield from` prefix.
- Discharge status: constructed by `fvk/up028-fix-spec.k` claim 1.

## PO2 - General unparenthesized tuple family

- Claim: for all source slices `S`, `fix(iter(bareTuple, S)) => "yield from (" + S + ")"`.
- Intent evidence: `SPEC.md` E1 names the whole class "unparenthesized tuple".
- Source evidence: V1 branches on AST tuple parenthesization, not on the concrete text `x`.
- Discharge status: constructed by `fvk/up028-fix-spec.k` claim 2.

## PO3 - Frame condition for all other iterable forms

- Claim: for all source slices `S`, `fix(iter(preserved, S)) => "yield from " + S`.
- Intent evidence: the public issue identifies only unparenthesized tuple iterable syntax as the defect.
- Source evidence: V1 keeps the previous source-slice behavior for the else branch.
- Discharge status: constructed by `fvk/up028-fix-spec.k` claim 3.

## PO4 - Classification adequacy

- Claim: the abstraction `bareTuple` corresponds to `Expr::Tuple { parenthesized: false, .. }`; `preserved` corresponds to all other iterable source forms in the focused model.
- Intent evidence: the issue is about tuple source form, and Ruff's AST exposes tuple parenthesization.
- Source evidence: `ExprTuple` contains `parenthesized: bool`; V1 uses that field directly.
- Discharge status: source-inspection obligation, not encoded as a K rewrite rule. No code change needed.

## PO5 - Compatibility and blast-radius control

- Claim: the fix does not alter public APIs, rule selection, diagnostics, or non-bare iterable fix output.
- Intent evidence: task asks for a minimal targeted source fix.
- Source evidence: only internal replacement construction in `yield_in_for_loop.rs` changed.
- Discharge status: source-inspection obligation. No code change needed.

## Commands to machine-check later

These commands are recorded only; they were not run.

```sh
cd fvk
kompile mini-up028-fix.k --backend haskell
kast --backend haskell up028-fix-spec.k
kprove up028-fix-spec.k
```
