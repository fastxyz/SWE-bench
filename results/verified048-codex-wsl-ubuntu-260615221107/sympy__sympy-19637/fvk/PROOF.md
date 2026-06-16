# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Formal Core

The machine-checkable core for a later run is represented by:

- `fvk/mini-kernS.k`: a minimal K-style semantics for the `kernS` control-flow
  fragment.
- `fvk/kernS-spec.k`: K-style reachability claims for the relevant branches.

Exact commands to run later, not executed in this session:

```sh
cd fvk
kompile mini-kernS.k --backend haskell
kast --backend haskell kernS-spec.k
kprove kernS-spec.k
```

Expected machine-check result after a full K setup: `#Top` for the stated local
claims, modulo the explicit abstraction of `sympify`.

## Function Claim

For every string input in the `kernS` domain, if `kernS` returns, it either:

- delegates to `sympify` without using a placeholder;
- raises the pre-existing unmatched-parenthesis `SympifyError`;
- uses a defined placeholder `kern` and then clears it; or
- falls back to the un-hacked string after a placeholder-path `TypeError`.

It never evaluates `kern` while `kern` is undefined.

## Branch Proof Sketch

1. Initial state has `hit = False`.
2. If the input has no `(` or contains quotes, the rewrite block is skipped.
   Since V1 places `hit = kern in s` inside the placeholder branch, this path
   contains no read of `kern`. The function proceeds to `sympify(s)` and returns
   before cleanup because `hit` is false.
3. If the input has unbalanced parentheses, `SympifyError` is raised before
   placeholder logic. V1 does not alter this path.
4. If the rewrite block runs and no hack space is introduced, the `if ' ' in s:`
   branch is skipped. `hit` remains false from initialization. The later
   `if not hit: return expr` branch returns before `Symbol(kern)` is evaluated.
   This proves PO-2.
5. If a hack space is introduced, the code assigns `kern`, replaces spaces, and
   only then updates `hit`. Thus `hit == True` implies `kern` has been assigned.
   The cleanup path is safe. This proves PO-3.
6. If the hacked parse raises `TypeError`, the fallback sets `s = olds` and
   `hit = False`. The retry therefore reaches the same safe non-cleanup return
   shape unless `sympify` raises its own exception. This proves PO-4.

## Issue Instance

For `s = "(2*x)/(x-1)"`, inspection of the rewrite rules gives:

- balanced parentheses;
- no quotes;
- no `*(` occurrence;
- no `-(` occurrence;
- therefore no inserted hack space after the rewrite sequence.

By PO-1 and PO-2, V1 leaves `hit` false, does not read `kern`, and delegates to
`sympify("(2*x)/(x-1)")`. The reported `UnboundLocalError` path is eliminated.

## Adequacy and Compatibility

The English meaning of these claims matches the intent-only spec in `SPEC.md`:
the proof removes the undefined-local bug without changing the documented
placeholder behavior or `kernS` public API. `FINDINGS.md` records no remaining
code bug requiring a V2 source edit.

## Test Guidance

No tests were modified or run. Tests for the issue input and for existing
placeholder examples should be kept unless and until the emitted K commands are
run successfully. Expression-semantics tests remain outside this local proof
because `sympify` is abstracted.
