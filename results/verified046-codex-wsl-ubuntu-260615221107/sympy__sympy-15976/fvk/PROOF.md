# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were run.

## Formal Core

The supporting K artifacts are:

- `fvk/mini-mathml.k`
- `fvk/mathml-symbol-spec.k`

Exact commands to machine-check later:

```sh
cd fvk
kompile mini-mathml.k --backend haskell
kast --backend haskell mathml-symbol-spec.k
kprove mathml-symbol-spec.k
```

Expected result after a successful machine check: `#Top` for every claim.

## Proof Sketch

The mini semantics models only the property under audit: MathML node shape. It
has distinct constructors for `MI`, `MSUB`, `MSUP`, `MSUBSUP`, `MROW`, and an
explicit bad-shape discriminator `MIWRAP`. A passing issue node
`MSUB(MI("x", false), MI("2", false))` and a failing issue node
`MIWRAP(MSUB(MI("x", false), MI("2", false)))` are different terms, so the
model can see the defect.

The function `printSymbol(base, supers, subs, bold)` corresponds to the branch
of `MathMLPresentationPrinter._print_Symbol` after `split_super_sub` and Greek
translation have produced the base, superscript list, and subscript list.

### Plain Branch

Claim `SYMBOL-PLAIN` starts with empty superscripts and empty subscripts. The
first matching rule for `printSymbol` rewrites directly to `MI(base, bold)`.
This discharges `PO-PLAIN-FRAME` and `PO-BOLD-FRAME`.

### Subscript Branch

Claim `SYMBOL-SUB` starts with an empty superscript list and a nonempty subscript
list. The subscript rule rewrites to:

```text
MSUB(MI(base, bold), join(subs))
```

No rule in the mini semantics wraps this result in `MI` or `MIWRAP`. This
discharges `PO-SUB-NO-OUTER-MI`.

For the concrete issue symbol, `PO-SPLIT-X2` supplies the static split
`"x2" -> base "x", supers empty, subs ["2"]`. `join(["2"])` rewrites to
`MI("2", false)`, so the result is exactly:

```text
MSUB(MI("x", false), MI("2", false))
```

That is the issue's corrected markup shape.

### Superscript Branch

Claim `SYMBOL-SUP` starts with a nonempty superscript list and an empty subscript
list. The superscript rule rewrites to:

```text
MSUP(MI(base, bold), join(supers))
```

No outer `MI` is introduced, discharging `PO-SUP-NO-OUTER-MI`.

### Subscript And Superscript Branch

Claim `SYMBOL-SUBSUP` starts with both script lists nonempty. The combined rule
rewrites to:

```text
MSUBSUP(MI(base, bold), join(subs), join(supers))
```

Again there is no outer `MI`, discharging `PO-SUBSUP-NO-OUTER-MI`.

### Script Join

The `join` rules are unchanged from V1's inherited implementation shape. A
single item becomes `MI(item, false)`. Multiple items become an `MROW` with
script identifiers separated by `MO(" ")`. This discharges `PO-JOIN-SCRIPTS`.

### Composition For The Issue Expression

The issue expression contains `x2` twice: once as a factor in `x2*z`, and once
as the base of `x2**3`. Static inspection shows `_print_Mul` appends the result
of `_print(term)` into an `mrow`, and `_print_Pow` appends the result of
`_print(e.base)` into `mfenced` for bases with `len(str(e.base)) > 1`. Since V1
made `_print_Symbol(x2)` return `msub` directly, neither composition point can
produce the old `mi(msub(...))` shape. This discharges `PO-ISSUE-EXPR`.

## Adequacy Gate

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` matches the
intent-only requirements in `fvk/INTENT_SPEC.md`. The only conflicting public
evidence is the old in-repo test shape, which `fvk/SPEC_AUDIT.md` marks
SUSPECT under the FVK intent-evidence rule because it encodes the reported bug.

## Test Recommendations

No test files were modified. Existing old shape tests are not redundant because
they assert legacy behavior that conflicts with the issue. If test edits were
allowed, the presentation-symbol tests should be updated to assert top-level
`msub`, `msup`, and `msubsup`, plus a regression assertion that presentation
MathML for `x2*z + x2**3` contains no `<mi><msub>` substring. Any test removal
would be conditioned on a future successful `kprove` result.

## Conclusion

The constructed proof discharges the proof obligations over the audited
observable. V1 stands unchanged.
