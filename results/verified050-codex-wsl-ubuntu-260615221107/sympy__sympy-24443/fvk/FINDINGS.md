# FVK Findings

Status: constructed, not machine-checked.

## F1 - Closed Code Bug: Inverse Presentation Generator Was Not Translated

Evidence: the public issue reports that `homomorphism(D3, D3, D3.generators, D3.generators)` raised `ValueError` and identifies the cause: "When `r[i]` is an inverted generator, the `in gens` test fails."

Input -> observed vs expected:

```text
domain = D3, codomain = D3, images = identity on D3.generators
observed pre-fix: ValueError("The given images do not define a homomorphism")
expected: a GroupHomomorphism, because every defining relator of D3 evaluates to identity under the identity map
```

V1 status: closed. `_image()` now iterates over `r.array_form`, translates by relator symbol through `gen_to_s`, and applies the signed exponent. This satisfies `PO1` and `PO2`.

## F2 - Closed Design Risk: Mapping Inverse Objects Directly Would Be Ambiguous

Evidence: a permutation group can in principle include both `g` and `g**-1` as separate generators. A relator occurrence of `x_i**-1` means the inverse of `x_i`, not the separate generator object that may compare equal to `g**-1` in the domain's generator list.

Input -> observed vs expected:

```text
relator syllable = (symbol x_i, power -1)
incorrect alternative: look up image for the permutation object g_i**-1 when it is also a generator key
expected: use images[g_i]**-1
```

V1 status: closed. The implementation maps symbols to positive domain generators and keeps the exponent signed. This satisfies `PO2` and `PO4`.

## F3 - Confirmed Non-Regression: FpGroup And FreeGroup Relator Evaluation

Evidence: for non-permutation domains, relator symbols already name the same free-group generators that key `images`.

Input -> observed vs expected:

```text
relator syllable = (symbol a, power -2)
expected: images[a]**-2
```

V1 status: satisfied. `gen_to_s` maps `a` to generator `a`, so the new fold computes `images[a]**-2`. This satisfies `PO3`.

## F4 - Confirmed Compatibility: No Public API Or Test-Suite Change

Evidence: the V1 patch changes only the private helper body inside `_check_homomorphism()`. It does not change `homomorphism()` arguments, public classes, return types, or tests.

Status: satisfied. This satisfies `PO5`.

## F5 - Proof Boundary: Constructed, Not Machine-Checked

Evidence: the task forbids running tests, Python code, or K tools. SymPy's real permutation and finitely presented group semantics are also richer than the small abstract K model used here.

Status: not a code bug. The proof package is a constructed proof over the targeted relator-evaluation property, with commands recorded in `PROOF.md` for future machine checking or deeper formalization. This satisfies `PO6`.
