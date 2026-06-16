# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or Django tests were run.

## Artifacts

- Semantics: `fvk/mini-django-query.k`.
- Claims: `fvk/query-in-spec.k`.
- Human spec and adequacy audit: `fvk/SPEC.md`.
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md`.
- Findings: `fvk/FINDINGS.md`.

Exact commands to run later:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-in-spec.k
kprove fvk/query-in-spec.k
```

Expected machine-check result: `#Top` for all claims if the abstract semantics
and claims parse as written.

## Proof Model

The K model treats query preparation as a small transition system over:

- a Boolean `has_select_fields`;
- an abstract selected-field state;
- an abstract annotation-mask state.

It is intentionally smaller than Django's real ORM. The abstraction is adequate
for this issue because the bug and the fix are entirely about whether lookup
preparation observes "explicit selected fields" and which one-column selection
it produces.

## Claim 1: Annotate plus alias then base `In`

Obligation: PO-001. Finding: F-001.

Initial state:

```text
query(false, defaultCols, maskNone)
```

Symbolic execution:

1. `annotate` preserves `has_select_fields == false`.
2. `aliasAfterAnnotate` changes the annotation mask to `maskAnnotation` but
   preserves `has_select_fields == false`.
3. `inPrep` takes the `false` branch and rewrites the selected field to
   `pkSelect`.

Post-state:

```text
query(false, pkSelect, maskEmpty)
```

This proves the issue path is narrowed to one pk column under the abstract
semantics.

## Claim 2: Explicit values then base `In`

Obligation: PO-002. Finding: F-004.

Initial state:

```text
query(false, defaultCols, maskNone)
```

Symbolic execution:

1. `setValues(explicit)` rewrites the query state to
   `query(true, explicitSelect, maskEmpty)`.
2. `inPrep` takes the `true` branch and preserves the explicit selection.

Post-state:

```text
query(true, explicitSelect, maskEmpty)
```

This proves that changing `has_select_fields` to explicit state does not break
the documented values-style escape hatch.

## Claim 3: Related non-primary-key target then base `In`

Obligation: PO-003. Finding: F-002.

Initial state:

```text
query(false, defaultCols, maskNone)
```

Symbolic execution:

1. `relatedInPrep(false, false)` represents the non-primary-key related target
   branch.
2. That branch schedules `setValues(target)` before `inPrep`.
3. `setValues(target)` rewrites the state to
   `query(true, targetSelect, maskEmpty)`.
4. `inPrep` takes the `true` branch and preserves `targetSelect`.

Post-state:

```text
query(true, targetSelect, maskEmpty)
```

This proves the related lookup regression risk named in the prompt is closed by
the V1 `set_values([target_field])` edit.

## Claim 4: Clone preserves explicit selected-field state

Obligation: PO-004. Finding: F-003.

Initial state:

```text
query(false, defaultCols, maskNone)
```

Symbolic execution:

1. `setValues(explicit)` sets the explicit-selection flag and selected field.
2. `clone` preserves the abstract query state.
3. `inPrep` observes `has_select_fields == true` and preserves the explicit
   selection.

Post-state:

```text
query(true, explicitSelect, maskEmpty)
```

The source justification for the `clone` transition is
`obj.__dict__ = self.__dict__.copy()` in `Query.clone()`.

## Claim 5: Annotate plus alias then one-row `Exact`

Obligation: PO-006. Finding: F-004.

Symbolic execution is the same as Claim 1 through annotation and alias. The
`exactPrepOne` transition then uses the same `has_select_fields == false`
discriminator and narrows the RHS to `pkSelect`.

Post-state:

```text
query(false, pkSelect, maskEmpty)
```

This confirms the V1 discriminator semantics remain coherent for the other
lookup path that uses `has_select_fields`.

## Adequacy and Compatibility

The formal claims are paraphrased and audited in `fvk/SPEC.md`. Each claim maps
to public issue text or public hints; none preserve the legacy
annotation-mask-derived property behavior.

PO-005 covers compatibility. The V1 patch changes private ORM internals only and
does not alter public signatures, public return shapes, or tests.

## Residual Risk

- The proof is constructed, not machine-checked.
- The K model is an abstraction of the relevant query-state transitions, not a
  full Python or Django semantics.
- Termination is not a meaningful separate obligation for these straight-line
  state transitions.
- SQL compiler behavior and database execution are not modeled; the proof covers
  the lookup-preparation state that determines the number and identity of RHS
  selected columns.

## Test Recommendation

Do not delete tests. Because the proof is not machine-checked, any redundancy
claim would be conditional. Useful public tests to keep or add after this
benchmark setting:

- annotate plus alias RHS query used in `__in` without `values()`;
- explicit `values()` RHS query used in `__in`;
- related non-primary-key `__in` RHS query;
- sliced one-row `Exact` RHS query with annotations and aliases.

## Verdict

All proof obligations are discharged by V1 under the constructed model. No
production-code V2 edit is justified.
