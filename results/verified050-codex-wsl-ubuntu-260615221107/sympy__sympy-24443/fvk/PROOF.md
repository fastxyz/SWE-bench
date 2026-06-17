# FVK Proof

Status: constructed, not machine-checked. No Python, test, or K command was run.

## Claims

The proof targets the abstract relator evaluator specified in `SPEC.md` and encoded in `fvk/mini-homomorphism.k` / `fvk/homomorphism-spec.k`.

- `C1`: Empty relator claim. Evaluating the identity relator returns the codomain identity.
- `C2`: Syllable fold claim. Evaluating `(sym, power) :: rest` multiplies the accumulator by `images[gen_to_s[sym]]**power` and continues with `rest`.
- `C3`: Inverse syllable claim. If `power < 0`, the same fold computes the inverse power of the mapped generator image; no lookup of the inverse free-group letter is needed.
- `C4`: Homomorphism criterion claim. `_check_homomorphism()` accepts iff every relator image is identity/equal under the existing codomain equality path.
- `C5`: Frame claim. Public API shape and non-permutation relator semantics are preserved.

## Constructed Proof Sketch

Base case: if `r.is_identity`, V1 returns `identity`. This proves `C1`.

Inductive step over `r.array_form`: assume the accumulator `w` equals the image of the already-processed relator prefix. For the next syllable `(sym, power)`, `PO1` gives `gen_to_s[sym]`. V1 sets `s = gen_to_s[sym]` and multiplies `w` by `images[s]**power` when `s` is an image key. Since `homomorphism()` completes `images` for every domain generator, this is the normal public path. If `power` is negative, group exponentiation denotes the inverse power, so the inverse generator case is handled without checking whether `r[i]` itself is in `gens`. This proves `C2` and `C3`.

Non-permutation preservation: for `FpGroup` and `FreeGroup`, `gen_to_s` maps each relator symbol back to the same free-group generator. Therefore each syllable `(a, p)` still contributes `images[a]**p`. This proves `C5` for the changed evaluator and discharges `PO3`.

Permutation-group correction: for `PermutationGroup`, `gen_to_s` maps presentation symbol `x_i` to `domain.generators[i]`. The reported failing case was an inverse free-group letter `x_i**-1`; its `array_form` syllable is still `(x_i, negative_power)`. V1 therefore maps through `x_i`, not through the inverse letter object, and applies the negative exponent to `images[domain.generators[i]]`. Under the identity map on `D3`, each defining relator evaluates to the same group word in `D3`, hence to identity. This removes the false `ValueError` path described in `F1`.

Homomorphism criterion: after `_image(r)` is computed, the surrounding loop and equality checks are unchanged from the baseline. A non-identity relator image still returns `False`, and all identity relator images return `True`. This proves `C4` under the same codomain equality assumptions as the original function.

## Proof-Derived Findings

No new source defect was found in V1. The only proof boundary is `F5`: the constructed proof was not machine-checked and does not prove unrelated SymPy algorithms such as finite-presentation generation or FpGroup confluence.

## Commands Not Run

The following are the commands that would be used to check the abstract K artifacts later. They were not executed.

```sh
cd fvk
kompile mini-homomorphism.k --backend haskell
kast --backend haskell homomorphism-spec.k
kprove homomorphism-spec.k
```

Expected machine-check result after a complete executable K formalization: `#Top`.
