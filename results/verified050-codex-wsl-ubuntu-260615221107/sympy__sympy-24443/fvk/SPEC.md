# FVK Spec

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

The audited unit is `repo/sympy/combinatorics/homomorphisms.py::_check_homomorphism()` and its nested `_image()` helper after the V1 patch. The observable behavior under audit is whether `homomorphism(domain, codomain, gens, images, check=True)` accepts exactly those generator-image assignments whose domain relators evaluate to the codomain identity.

## Intent Specification

- Public issue evidence: "`_check_homomorphism` is broken on PermutationGroups" and the reproducer `homomorphism(D3, D3, D3.generators, D3.generators)` raises `ValueError`.
  Semantic obligation: the identity assignment on a permutation group must pass the relator check.

- Public issue evidence: "When `r[i]` is an inverted generator, the `in gens` test fails."
  Semantic obligation: relator evaluation for a `PermutationGroup` must handle inverse presentation generator syllables.

- Public issue evidence: "I think the whole thing can be greatly simplified."
  Semantic obligation: a simpler formulation is acceptable if it preserves the homomorphism criterion and non-permutation behavior.

- Source/docstring evidence: `homomorphism()` says "If the given images of the generators do not define a homomorphism, an exception is raised."
  Semantic obligation: `_check_homomorphism()` returns false for at least one relator image not equal to identity, and true when every relator image is identity.

- Source evidence: `PermutationGroup.presentation()` creates free-group generator symbols `x_0`, `x_1`, ... from `self.generators` by position.
  Semantic obligation: for permutation-group domains, presentation symbol `x_i` maps to `domain.generators[i]`.

## Domain And Preconditions

- `domain` is a `PermutationGroup`, `FpGroup`, or `FreeGroup` accepted by `homomorphism()`.
- `codomain` is a `PermutationGroup`, `FpGroup`, or `FreeGroup` accepted by `homomorphism()`.
- `images` is the completed dictionary produced by `homomorphism()`, so every domain generator has an image. Internal callers such as `group_isomorphism()` also construct images over `G.generators`.
- Relators are represented as `FreeGroupElement.array_form`, a sequence of `(symbol, signed_power)` syllables.
- For permutation-group domains, presentation generators remain positionally aligned with `domain.generators`; this is the same assumption the previous implementation made with `domain.generators[gens.index(...)]`.
- The proof is partial correctness: it shows the check result if the presentation construction and equality tests return. It does not prove termination or the completeness of SymPy's finite-presentation algorithm.

## Formal Model

Let a relator be a list of syllables:

```text
R = [(sym_1, p_1), ..., (sym_n, p_n)]
```

Let `P` be the presentation-symbol map:

```text
PermutationGroup: P[sym_i] = domain.generators[i]
FpGroup/FreeGroup: P[sym_i] = the free-group generator with symbol sym_i
```

Let `I` be the image map supplied to `_check_homomorphism()`. The intended `_image()` value is:

```text
eval([], P, I) = codomain.identity
eval((sym, p) :: rest, P, I) =
    eval(rest, P, I, accumulator * I[P[sym]]**p)
```

This is encoded in `fvk/mini-homomorphism.k` and `fvk/homomorphism-spec.k` as an abstract K-style semantics:

```k
rule eval(.Rel, P:PMap, I:IMap, W:Elem) => W
rule eval((SYM:Sym, POW:Int) REST:Relator, P:PMap, I:IMap, W:Elem)
  => eval(REST, P, I, W * (lookupI(I, lookupP(P, SYM)) ^ POW))
```

## Postconditions

- `SP1`: `_image(identity_relator) == codomain.identity`.
- `SP2`: For every relator syllable `(sym, power)`, `_image()` multiplies by `images[gen_to_s[sym]]**power`.
- `SP3`: Negative powers are handled by the signed exponent; no branch depends on the inverse free-group letter being a member of the positive presentation-generator list.
- `SP4`: `_check_homomorphism()` returns `False` if any relator image is not equal to the codomain identity; otherwise it returns `True`.
- `SP5`: For `FpGroup` and `FreeGroup` domains, mapping a relator symbol to the same free-group generator preserves the previous intended evaluation semantics.
- `SP6`: Public API, function signatures, return types, and test files are unchanged.

## Adequacy Audit

The formal model says exactly what the public issue requires: inverse presentation generator syllables are evaluated through their generator symbol and signed exponent. It does not prove unrelated properties of `PermutationGroup.presentation()`, `FpGroup.equals()`, or `make_confluent()`. Those are treated as trusted surrounding SymPy behavior outside this targeted issue.
