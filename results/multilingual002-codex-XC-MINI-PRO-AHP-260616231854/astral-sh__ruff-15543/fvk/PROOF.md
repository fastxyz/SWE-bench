# Constructed FVK Proof

Status: constructed, not machine-checked. K tooling and tests were not run.

## Claims proved in the model

The formal core is in `mini-up028-fix.k` and `up028-fix-spec.k`.

1. Reported singleton case: `fix(iter(bareTuple, "x,"))` rewrites to `yield from (x,)`.
2. Bare tuple family: for any source slice `S`, `fix(iter(bareTuple, S))` rewrites to `yield from (` + `S` + `)`.
3. Preserved path: for any source slice `S`, `fix(iter(preserved, S))` rewrites to `yield from ` + `S`.

## Symbolic execution sketch

The mini semantics has two rewrite rules:

- `fix(iter(bareTuple, S)) => ("yield from (" +String S) +String ")"`
- `fix(iter(preserved, S)) => "yield from " +String S`

For claim 1, instantiate the first rule with `S = "x,"`. One rewrite step reaches `yield from (x,)`, matching the right-hand side exactly.

For claim 2, leave `S` symbolic and apply the first rule. One rewrite step reaches the claimed parenthesized replacement for every `S`.

For claim 3, leave `S` symbolic and apply the second rule. One rewrite step reaches the claimed source-preserving replacement for every preserved input.

No loop circularity is needed because the audited replacement-construction fragment is branch-only and has no loop or recursion. The proof uses reachability by direct axiom application and transitivity over a single step.

## Connection to V1 source

The V1 Rust code computes the source slice as before, then branches:

- `Expr::Tuple(ast::ExprTuple { parenthesized: false, .. })` maps to `bareTuple`.
- Every other iterable maps to `preserved`.

The final `format!("yield from {contents}")` is represented by the second stage of each K rule. The bare-tuple branch first turns `S` into `(` + `S` + `)`, which makes the reported singleton case `yield from (x,)`.

## Adequacy and residual risk

The model preserves the observable relevant to the defect: exact replacement string shape. It deliberately abstracts away parser, semantic-model, diagnostic, and edit-application machinery, because the issue is not about whether UP028 detects the loop; it is about invalid replacement text once it does.

Residual risks:

- Constructed only: `kompile`, `kast`, and `kprove` were not run.
- Partial scope: the proof does not establish termination, full Ruff parser correctness, or full semantic safety of UP028.
- Tests should not be removed based on this proof; integration and syntax-validation coverage remain valuable until the K commands are actually run and project tests are available.

## Reproduce the machine check later

```sh
cd fvk
kompile mini-up028-fix.k --backend haskell
kast --backend haskell up028-fix-spec.k
kprove up028-fix-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top`.
