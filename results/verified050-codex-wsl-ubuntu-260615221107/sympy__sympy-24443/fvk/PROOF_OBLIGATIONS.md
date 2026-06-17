# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Presentation Symbol Mapping Is Total On Relators

For every non-identity relator syllable `(sym, power)` processed by `_image()`, `gen_to_s[sym]` is defined.

Evidence:

- For `FpGroup` and `FreeGroup`, `gens = domain.generators`, and relators are words over that free group.
- For `PermutationGroup`, `presentation = domain.presentation()`, `gens = presentation.generators`, and `rels = presentation.relators`; relator symbols come from those presentation generators.
- `PermutationGroup.presentation()` constructs presentation symbols from `domain.generators` by position.

Discharges: `SP2`, `F1`.

## PO2 - Inverse Syllables Use Signed Powers, Not Membership Tests

For every syllable `(sym, power)`, `_image()` must multiply by `images[gen_to_s[sym]]**power`. If `power < 0`, the group exponent operation supplies the inverse image. The proof must not require `r[i] in gens` for inverse letters.

Evidence:

- Public issue names the failed inverse-membership branch.
- V1 code reads `for sym, power in r.array_form`, then `s = gen_to_s[sym]`, then `w = w*images[s]**power`.

Discharges: `SP2`, `SP3`, `F1`, `F2`.

## PO3 - Non-Permutation Behavior Is Preserved

For `FpGroup` and `FreeGroup` domains, replacing `r[i]`/`array_form` dual indexing with symbol mapping computes the same intended image:

```text
old intended value for a^p: images[a]**p
new value for (symbol a, p): images[gen_to_s[a]]**p = images[a]**p
```

Discharges: `SP5`, `F3`.

## PO4 - Homomorphism Criterion Is Preserved

`_check_homomorphism()` returns `True` exactly when every relator image is equal to the codomain identity under the available equality predicate:

- if `codomain` is an `FpGroup`, use `codomain.equals(_image(r), identity)`, retrying after `make_confluent()` as before;
- otherwise use `_image(r).is_identity`;
- return `False` immediately on a failed relator;
- return `True` after all relators pass.

Discharges: `SP4`, `F1`, `F2`.

## PO5 - Compatibility Frame

The patch must not change public signatures, return types, accepted input types, or tests. It may change only the internal relator-image calculation.

Discharges: `SP6`, `F4`.

## PO6 - Verification Honesty

Because execution is forbidden, no claim may assert that tests, Python examples, or K proof commands were run. The proof may be reported only as constructed, not machine-checked.

Discharges: `F5`.
