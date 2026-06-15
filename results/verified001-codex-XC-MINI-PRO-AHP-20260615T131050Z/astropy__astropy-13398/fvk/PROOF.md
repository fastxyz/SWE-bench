# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Artifacts

- Semantics: `mini-coordinate-transforms.k`
- Claims: `itrs-observed-spec.k`
- Human spec: `SPEC.md`
- Adequacy files: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`

Machine-check commands to run later:

```sh
kompile fvk/mini-coordinate-transforms.k --backend haskell
kast --backend haskell fvk/itrs-observed-spec.k
kprove fvk/itrs-observed-spec.k
```

Expected machine result if the mini semantics and claims parse as written:
`kprove` returns `#Top`.

## Proof Sketch

### Matching-location ITRS to observed

Claims C1 and C2 start with:

```k
itrsToObserved(itrs(L, T), observed(kind, L, TO, noRefrac), V)
```

The first matching semantic rule for a concrete observed location rewrites this
in one step to:

```k
coord(observed(kind, L, TO, noRefrac), rotate(kind, L, V))
```

There is no premise that compares or rewrites `T` and `TO`. Thus the proof
establishes partial correctness of the time-invariant direct topocentric path
for no-refraction AltAz and HADec.

### Differing-location ITRS to observed

Claim C3 assumes `L1 =/=K L2` and `L2 =/=K noLoc`. The corresponding semantic
rule rewrites the input to:

```k
coord(observed(K, L2, TO, noRefrac),
      rotate(K, L2, selfITRS(L1, L2, T, chooseTime(TO, T), V)))
```

The abstract `selfITRS` symbol represents the existing Astropy ITRS
self-transform. Since the new local observed rotation occurs only after this
symbol, the constructed proof preserves the intended geocentric compatibility
boundary instead of proving the rejected direct-subtraction behavior.

### Observed to ITRS

Claim C4, with matching observed and target ITRS locations, rewrites:

```k
observedToITRS(observed(K, L, TO, noRefrac), itrs(L, TOut), V)
```

to:

```k
coord(itrs(L, TOut), invRotate(K, L, V))
```

Claim C5 adds `L1 =/=K L2`; the semantic rule wraps the inverse-rotated vector
in `selfITRS(L1, L2, TOut, TOut, ...)`, matching V1's construction of a
topocentric ITRS coordinate at the observed location followed by
`transform_to(itrs_frame)`.

### Refraction

The refraction claims split on `obstime`:

- `TO == none` rewrites to `errNoObstime`.
- `TO =/=K none` rewrites through `toCIRS`/`refract` for ITRS->observed or
  `unrefract`/`fromCIRS` for observed->ITRS.

These abstract functions correspond to V1's reuse of `cirs_to_itrs_mat`,
`CIRS(...)`, and the existing CIRS observed transform functions.

### Intermediate transforms and earth-location projection

The intermediate claims rewrite ITRS->CIRS/TETE to frames with the source ITRS
location and CIRS/TETE->ITRS to frames with the requested target ITRS location.
The earth-location claim rewrites `earthLocation(itrs(L, T), V)` to
`addLocation(L, V)`, matching the V1 `data + location.get_itrs().cartesian`
property.

## Trusted Base and Limits

The constructed proof depends on:

- adequacy of the mini coordinate-transform semantics for the branch/origin
  behavior under audit;
- the existing Astropy ITRS self-transform, represented by `selfITRS`;
- the existing CIRS/refraction machinery, represented by `toCIRS`, `fromCIRS`,
  `refract`, and `unrefract`;
- K reachability logic and a future `kprove` machine check.

It does not prove termination, floating-point accuracy, ERFA correctness,
matrix algebra identities, or the entire Astropy transform graph. Those are
outside this mini-model and remain test/manual-review obligations.

## Test Redundancy Recommendation

No tests were edited or recommended for removal. Because the proof is
constructed but not machine-checked, and because it abstracts real numerical
semantics, all existing tests should be kept. New tests would be appropriate
for topocentric ITRS AltAz/HADec round trips once execution is allowed.

## Verification Verdict

The constructed proof supports `V2 == V1` for production code. Findings F1-F5
do not require a code edit: F1 is a resolved intent conflict, F2 is fixed by V1,
F3/F4 are positive guards, and F5 is an explicit proof capability boundary.
