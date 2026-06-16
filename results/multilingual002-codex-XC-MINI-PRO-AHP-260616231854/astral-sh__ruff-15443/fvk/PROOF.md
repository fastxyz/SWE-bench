# FVK Proof

Status: constructed, not machine-checked.

## Reproduce Later

These commands are intentionally not run in this benchmark session:

```sh
kompile fvk/mini-ruff-calls.k --backend haskell
kast --backend haskell fvk/builtin-module-spec.k
kprove fvk/builtin-module-spec.k
```

Expected machine-check result in a K-enabled environment: all claims discharge to `#Top`.

## Proof Sketch

The mini semantics models only the behavior relevant to the issue: a resolved call target is a pair `(module, member)`, and each rule either emits or does not emit. The implementation evidence establishes that Ruff's semantic model uses the empty module segment for unqualified builtin bindings and the explicit segment `"builtins"` for references through the `builtins` module.

For `S102`, V1 evaluates `resolve_qualified_name(func)` and applies `matches!(qualified_name.segments(), ["" | "builtins", "exec"])`. Symbolic execution over this predicate has three relevant branches:

1. `qname("builtins", "exec")`: the alternation accepts `"builtins"` and the member is `"exec"`, so the diagnostic branch executes. This discharges PO-01 and resolves F-01 for `S102`.
2. `qname("", "exec")`: the alternation accepts the empty builtin-binding segment, so existing unqualified `exec()` behavior is preserved. This discharges PO-02.
3. `qname("builtin", "exec")`: the alternation rejects `"builtin"`, so the diagnostic branch is unreachable. This discharges PO-03 and resolves F-02 for `S102`.

For `PTH123`, V1 evaluates `resolve_qualified_name(&call.func)` and dispatches `BuiltinOpen` only under the match arm `["" | "builtins", "open"]`. Symbolic execution has the same module-name split plus the existing exclusion block:

1. `qname("builtins", "open")` with all exclusion flags false reaches `Some(BuiltinOpen.into())`, then the caller emits when `PTH123` is enabled. This discharges PO-04 and resolves F-01 for `PTH123`.
2. `qname("", "open")` with all exclusion flags false follows the same branch, preserving unqualified `open()` behavior. This discharges PO-05.
3. `qname("builtin", "open")` does not match the arm and falls through to `_ => None`, so no `PTH123` diagnostic is created. This discharges PO-06 and resolves F-02 for `PTH123`.
4. `qname("builtins", "open")` with non-default `closefd`, non-default `opener`, or a file-descriptor first argument returns `None` before `BuiltinOpen` is constructed. V1 did not edit this block. This discharges PO-07 and F-03.

PO-08 follows from a source-level frame proof: V1 changes no signatures, exported names, rule code registrations, diagnostic structs, messages, or call shapes. PO-09 follows from static source inspection: the exact singular module literal `"builtin"` no longer appears in the audited source slice, while other builtin-rule patterns use `["" | "builtins", ...]`.

## Adequacy Result

The English meaning of the claims matches the public issue intent: `builtins` is accepted, `builtin` is rejected, unqualified builtin calls remain accepted, and unrelated `PTH123` compatibility exclusions remain unchanged. No proof obligation relies on hidden tests, benchmark verdicts, or legacy behavior that the issue marks as buggy.

## Residual Risk

This is a partial-correctness proof over a focused mini semantics of qualified-name dispatch. It does not prove the whole Ruff linter, parser, import resolver, or command-line integration. The proof is constructed, not machine-checked, because the benchmark forbids running K tooling. No test removal is recommended without a later successful `kprove` run.
