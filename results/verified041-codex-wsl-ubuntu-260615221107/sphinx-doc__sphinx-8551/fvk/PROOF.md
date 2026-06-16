# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Claims proved by construction

The K claims in `sphinx-xref-spec.k` prove the obligations listed in
`PROOF_OBLIGATIONS.md` for the mini semantics in `mini-sphinx-xref.k`.

## Proof sketch

`FIELD-CONTEXT` rewrites by the `processFieldXref` rule. The rule replaces the
node module/class fields with symbolic `M` and `C`, while framing target,
display, and `refspecific`. This matches the V1 override of
`PythonDomain.process_field_xref()`.

`PLAIN-FIELD`, `DOT-FIELD`, and `TILDE-FIELD` each rewrite by one
`makeFieldXref` rule. The plain case lands on `ref(M, C, A, false, A)`, the dot
case on `ref(M, C, A, true, A)`, and the tilde case on
`ref(M, C, ModA, false, A)`. These are the exact cases controlled by
`PyXrefMixin.make_xref()`.

`RESOLVE-MOD` composes `resolveFieldRaw(Mod, NoCls, RawA)` to
`resolveIssue(ref(Mod, NoCls, A, false, A))`, then applies the issue-database
resolver rule to reach `resolved(ObjModA)`.

`RESOLVE-SUBMOD` takes the same two rewrite steps with `ModSubmod`, reaching
`resolved(ObjModSubmodA)`. Because the plain field node is not `refspecific`,
the ambiguous suffix-search branch is unreachable in this claim.

`RESOLVE-NONMODULE-PLAIN` rewrites plain `A` with `NoMod` to
`ref(NoMod, NoCls, A, false, A)`, then to `noMatch`. This is the public hint's
guard against a silent suffix link in non-module scope.

`RESOLVE-NONMODULE-DOT` rewrites `.A` with `NoMod` to
`ref(NoMod, NoCls, A, true, A)`, then to
`ambiguous(ObjModA, ObjModSubmodA)`. This proves V1 did not remove explicit
leading-dot fuzzy behavior.

There are no loops or recursive calls in the modeled unit, so no circularity
claim is required.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases every nontrivial claim. `SPEC_AUDIT.md`
checks those clauses against the intent-only obligations and marks all required
clauses pass. `PUBLIC_COMPATIBILITY_AUDIT.md` records no signature or dispatch
compatibility failure.

## Test recommendation

Recommended tests to add or keep, not written in this task:

- Reproduction with `mod.A` and `mod.submod.A`, asserting no false ambiguity
  warning for unqualified field type `A` under `mod` and `mod.submod`.
- Assertion that the `mod.submod` field type resolves to `mod.submod.A`.
- Non-module-scope plain `A` with only module-qualified `*.A` objects, asserting
  it does not silently link to a suffix match.
- Existing integration tests for unrelated Python-domain xrefs should be kept.

No test removal is recommended until the emitted K commands are actually run and
return `#Top`.

## Machine-check commands

These commands are intentionally not executed in this session:

```sh
kompile fvk/mini-sphinx-xref.k --backend haskell
kast --backend haskell fvk/sphinx-xref-spec.k
kprove fvk/sphinx-xref-spec.k
```

Expected result after machine checking: all claims reduce to `#Top`.
