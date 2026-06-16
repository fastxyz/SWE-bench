# FVK Proof

Status: constructed, not machine-checked. No commands were executed.

## Claims

The proof is over the small formatter model in `mini-enum-format.k` and the
claims in `enum-default-spec.k`.

- `NAMED-ENUM-DESCRIPTION`: named enum members reach `Class.Member`.
- `FLAG-COMPOSITE-DESCRIPTION`: named flag combinations reach
  `Class.A|Class.B`.
- `UNNAMED-ENUM-FALLBACK`: nameless enum values reach the repr fallback.
- `OTHER-OBJECT-FALLBACK`: non-enum objects reach the repr fallback.
- `SIGNATURE-NAMED-ENUM-DEFAULT`: signature default formatting appends the
  named enum description result.

## Constructed Proof Sketch

For `NAMED-ENUM-DESCRIPTION`, symbolic execution starts with
`objectDescription(enumNamed(C, N, R))`. The first matching rule in the
semantics rewrites it to `dot(C, N)` under the side condition that `N` is not
empty. The `dot` rule rewrites to `C + "." + N`. This proves PO-02.

For `FLAG-COMPOSITE-DESCRIPTION`, symbolic execution starts with
`objectDescription(flagNamed(C, N1 | N2, R))`. The flag rule rewrites to
`qualifyFlags(C, N1 | N2)`. The recursive qualifier takes one genuine rewrite
step per component, producing `dot(C, N1) + "|" + dot(C, N2)`, then the `dot`
rules reduce each component to `C.N1` and `C.N2`. This proves PO-05 for the
two-component representative case; additional components follow by the same
structural recursion over the pipe-separated name list.

For `UNNAMED-ENUM-FALLBACK`, the model starts with
`objectDescription(enumUnnamed(C, R))`. No member-reference rule applies. The
fallback rule rewrites to `cleanRepr(R)`, and `cleanRepr` rewrites to `R`. This
proves the negative part of PO-05: the constructed result is not `C.None`.

For `OTHER-OBJECT-FALLBACK`, `objectDescription(other(R))` rewrites directly
through `cleanRepr(R)` to `R`. This proves the modeled frame condition in
PO-04. The concrete Python source preserves the detailed dict/set/frozenset
branches by leaving them unchanged.

For `SIGNATURE-NAMED-ENUM-DEFAULT`, symbolic execution starts with
`stringifyDefault(P, enumNamed(C, N, R))`. The signature rule rewrites this to
`P + objectDescription(enumNamed(C, N, R))`. By transitivity with
`NAMED-ENUM-DESCRIPTION`, the result reaches `P + C + "." + N`. This proves
PO-03.

There are no loops in the audited source slice, so no circularity claim is
needed. The proof is partial correctness over the modeled formatting calls; it
does not prove termination of the whole Sphinx build.

## Adequacy Result

The English meaning of the claims matches `SPEC.md` intent items I1-I5. The
pre-fix ugly repr string is treated as suspect legacy behavior, and the proof
does not rely on it as an oracle.

## Machine-Check Commands

These commands are provided for later reproduction. They were not run here.

```sh
cd fvk
kompile mini-enum-format.k --backend haskell
kast --backend haskell enum-default-spec.k
kprove enum-default-spec.k
```

Expected machine-check result after installing and running the K toolchain:
`kprove` should reduce all claims to `#Top`.

## Test Recommendation

Do not remove tests based on this constructed proof alone. After machine
checking, direct unit coverage of named enum defaults would be subsumed by
`NAMED-ENUM-DESCRIPTION` and `SIGNATURE-NAMED-ENUM-DEFAULT`, but integration
coverage for autodoc rendering should remain because the proof models only the
formatter slice.
