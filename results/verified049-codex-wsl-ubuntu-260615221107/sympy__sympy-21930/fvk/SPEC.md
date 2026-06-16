# FVK Spec for sympy__sympy-21930

Status: constructed from public intent and source inspection only. No tests,
Python, or K tooling were run.

## Scope

The audited observable is LaTeX output for powers whose base is a
second-quantization creation operator. The relevant source units are:

- `repo/sympy/printing/latex.py`: `LatexPrinter._print_Pow` and
  `LatexPrinter._helper_print_standard_power`.
- `repo/sympy/physics/secondquant.py`: `Creator._latex_power_base`,
  `CreateBoson._latex`, and `CreateFermion._latex`.

The proof domain is partial correctness of printing: if the printer reaches the
power-formatting branch for an in-domain expression, the produced string has the
specified grouping. Termination is not separately proved.

## Intent Spec

I1. A powered bosonic creation operator must not render as a LaTeX double
superscript. For a base printed as `b^\dagger_{i}` and exponent `e`, the powered
base must render as `{b^\dagger_{i}}^{e}`.

I2. The issue names the secondquant module and the daggered double-superscript
form, so the same grouping obligation applies to the like-shaped fermionic
creation operator base `a^\dagger_{i}`.

I3. Unpowered creation-operator LaTeX is not reported as faulty and public tests
pin it as `b^\dagger_{i}` and `a^\dagger_{p}`. The fix must preserve those
strings when the operator is printed directly or as a non-powered factor.

I4. Existing generic LaTeX behavior for symbols, functions, derivatives,
non-creator bases, negative rational commutative powers, and root notation must
be preserved except where the public issue requires secondquant creator grouping.

I5. No public API signature or required caller contract should change. Any
power-base customization must be optional and must leave objects without the
custom hook on the legacy path.

## Public Evidence Ledger

E1. Source: prompt. Quote: "Issues with Latex printing output in second
quantization module". Obligation: audit secondquant LaTeX, not a general
mathematical simplification.

E2. Source: prompt. Quote: `b^\dagger_{0}^{2}`. Obligation: this exact shape is
the faulty output because LaTeX interprets it as a double superscript.

E3. Source: prompt. Quote: "It should be correct by adding curly brackets
`{b^\dagger_{0}}^{2}`". Obligation: group the whole daggered creation-operator
base with braces before appending the outer power.

E4. Source: public tests. Quote: `assert latex(o) == "b^\\dagger_{i}"`.
Obligation: unpowered `Bd(i)` output is preserved without outer braces.

E5. Source: public tests. Quote: `assert latex(Fd(p)) == r'a^\dagger_{p}'`.
Obligation: unpowered `Fd(p)` output is preserved without outer braces.

E6. Source: public tests. Quote: `assert latex(x_star**2) ==
r"\left(x^{*}\right)^{2}"`. Obligation: existing symbol superscript protection
through `parenthesize_super` is preserved.

E7. Source: implementation. Fact: `CreateBoson._latex` and
`CreateFermion._latex` both emit daggered bases with an internal superscript.
Obligation: the hook can be placed on their shared `Creator` base class.

E8. Source: implementation. Fact: `LatexPrinter._print_Pow` has both a standard
power path and a folded fractional-power path that append `^{...}` to a printed
base. Obligation: both paths must consult the custom grouped base.

## Formal Spec English

C1. Standard power claim: for any creation operator whose direct LaTeX is `L`
and any exponent string `E`, the standard power printer returns `{L}^{E}`.

C2. Folded fractional-power claim: for any creation operator whose direct LaTeX
is `L` and any folded fractional exponent `P/Q`, the folded power printer
returns `{L}^{P/Q}`.

C3. Unpowered creator frame claim: directly printing a creation operator still
returns its existing direct LaTeX `L`, not `{L}`.

C4. Non-hook frame claim: if a base has no `_latex_power_base` hook, the power
printer follows the same branch-specific behavior as before V1/V2.

C5. Compatibility claim: adding `_latex_power_base` introduces no required
argument to existing public methods and no changed return shape for direct
operator printing.

## Adequacy Audit

- C1 passes I1 and I3: it states the exact brace grouping the prompt requests
  only at the powered output point.
- C2 passes I1, I2, and E8: it covers the same bug mechanism in the other
  branch that appends an outer power to a printed base.
- C3 passes I3, E4, and E5: it explicitly prevents changing direct `Bd` and
  `Fd` output.
- C4 passes I4 and E6: it preserves unrelated LaTeX printer behavior.
- C5 passes I5: the hook is optional and private, and existing signatures are
  unchanged.

No formal-English claim is candidate-derived without public evidence. The only
generalization beyond the prompt example is from `Bd` to `Fd`, justified by the
same `Creator` role and identical dagger-superscript failure shape.

## Public Compatibility Audit

- Changed public class surface: `Creator` now has a private
  `_latex_power_base(self, printer)` method. This does not change construction,
  `_latex`, `apply_operator`, aliases `B`/`Bd`/`F`/`Fd`, or any existing method
  signature.
- Changed printer behavior: `LatexPrinter._print_Pow` consults the private hook
  only when present. Existing objects without the hook stay on the old code
  paths.
- Public callsites: source inspection found direct `_latex` expectations for
  `Bd` and `Fd`; those are preserved because `_latex_power_base` is only called
  from power printing.
- Subclass/override risk: current in-tree `Creator` subclasses are
  `CreateBoson` and `CreateFermion`; both require the same grouping. No existing
  override is made incompatible.

## K Artifact Index

The supporting K-style artifacts are:

- `fvk/mini-python-latex.k`: minimal string-printing semantics for the audited
  fragment.
- `fvk/secondquant-latex-spec.k`: claims corresponding to C1 through C4. C5 is
  discharged by the public compatibility audit above.

Expected, not executed:

```sh
kompile fvk/mini-python-latex.k --backend haskell
kast --backend haskell fvk/secondquant-latex-spec.k
kprove fvk/secondquant-latex-spec.k
```
