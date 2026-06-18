# Proof

Status: constructed, not machine-checked.

No `kompile`, `kprove`, Python, or tests were run. The commands below are the exact commands to run later in an environment with K installed.

## Target

Target code: `repo/sympy/printing/repr.py`

Relevant public entry point: `srepr(expr, **settings)`, which constructs `ReprPrinter(settings).doprint(expr)`.

V1 added explicit printer methods for Python `dict`, SymPy `Dict`, Python `set`, and Python `frozenset`.

## Formal artifacts

- Semantics: `fvk/mini-python.k`
- Claims: `fvk/srepr-containers-spec.k`
- Intent and adequacy artifacts: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`
- Findings: `FINDINGS.md`

## Constructed proof sketch

The mini semantics models the relevant printer fragment as a value-to-string transition:

1. `srepr(V)` rewrites to `reprOf(V)`.
2. `reprOf(Sym("x"))` rewrites to `Symbol('x')`.
3. Existing list and tuple behavior rewrites by applying `reprSeq` to each element.
4. V1 set behavior rewrites nonempty sets to `{` plus `reprSeq(sortVals(...))` plus `}`; empty sets rewrite to `set()`.
5. V1 dict behavior rewrites dicts to `{` plus `reprPairs(sortPairs(...))` plus `}`.
6. `reprPairs` recursively prints both key and value with `reprOf`.
7. `reprSeq` and `reprPairs` provide the structural-recursion circularities for finite modeled containers.

For the issue examples:

- `srepr(PySet(Sym("x") :: Sym("y") :: .Vals))`
- rewrites to `reprOf(PySet(...))`
- rewrites to `"{" + reprSeq(sortVals(Sym("x") :: Sym("y") :: .Vals)) + "}"`
- concrete `sortVals` keeps x before y
- `reprSeq` recursively rewrites `Sym("x")` and `Sym("y")`
- final result is `{Symbol('x'), Symbol('y')}`.

For dict:

- `srepr(PyDict(pair(Sym("x"), Sym("y")) :: .Pairs))`
- rewrites to `reprOf(PyDict(...))`
- rewrites to `"{" + reprPairs(sortPairs(pair(...))) + "}"`
- singleton `sortPairs` preserves the pair
- `reprPairs` recursively prints key and value
- final result is `{Symbol('x'): Symbol('y')}`.

List and tuple claims follow the pre-existing rules and show V1 does not alter their modeled output.

## Residual obligations and trusted base

- The proof is constructed, not machine-checked.
- The mini semantics is an abstraction of the relevant Python printer dispatch, not a full Python semantics.
- `default_sort_key` is represented by abstract `sortVals` and `sortPairs`, with concrete rules only for the x/y issue cases and singleton containers.
- Termination is not proved for arbitrary recursive object graphs. The modeled domain is finite acyclic containers.

These residuals do not produce a V1 counterexample because the reported defect is recursive content printing, which is represented directly in the claims.

## Reproduce the machine check later

Run from the `fvk/` directory:

```sh
kompile mini-python.k --backend haskell
kast srepr-containers-spec.k --definition mini-python-kompiled --module SREPR-CONTAINERS-SPEC --sort K
kprove srepr-containers-spec.k --definition mini-python-kompiled --spec-module SREPR-CONTAINERS-SPEC
```

Expected result if the artifacts and local K version agree: `kprove` returns `#Top`. Until that happens, the proof remains constructed, not machine-checked.

## Test recommendation

No test files were modified. Because the proof was not machine-checked, no test removal is recommended. Future visible tests for `srepr({x, y})`, `srepr({x: y})`, empty containers, and regression checks for list/tuple should be kept unless `kprove` returns `#Top` and maintainers decide the unit checks are redundant.
