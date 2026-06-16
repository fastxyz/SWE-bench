# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No production source edit is justified by the FVK audit. The V1 matcher
`^([^\W\d_]+)([0-9]+)$` discharges the issue-family obligations while avoiding
the multi-digit regression risk of a direct greedy `\w+` replacement.

## Why No V2 Source Change

- F-001 and PO-1/PO-2/PO-5 show the reported `ω0` pretty-printing defect is
  fixed by V1.
- F-002 and PO-3 show V1 preserves multi-digit ASCII suffixes such as `x10`.
- F-003 and PO-4 show broader names with internal digits or leading underscores
  are not required by the public intent and should not be broadened silently.
- F-004 and PO-6 show explicit separator behavior is framed.

## Future Work Outside This Benchmark

1. Add a unit test for `split_super_sub("ω0") == ("ω", [], ["0"])`.
2. Add a unicode pretty-printer test showing `Symbol("ω0")` renders with
   subscript zero.
3. Optionally add a regression test for `split_super_sub("x10")` to guard
   against a future greedy `\w+` rewrite.
4. Run the FVK machine-check commands from `SPEC.md` and `PROOF.md` in an
   environment with K installed.

## Commands To Run Later

```sh
cd fvk
kompile mini-symbol-conventions.k --backend haskell
kast --backend haskell symbol-conventions-spec.k
kprove symbol-conventions-spec.k
```

Do not remove any tests unless those commands return `#Top` and the removed
tests are wholly within the verified domain.
