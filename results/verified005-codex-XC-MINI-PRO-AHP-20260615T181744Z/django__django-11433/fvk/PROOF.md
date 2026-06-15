# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Artifacts

- Semantics: `mini-model-form.k`
- Claims: `construct-instance-spec.k`
- Intent/adequacy: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`,
  `PUBLIC_COMPATIBILITY_AUDIT.md`

## Machine-Check Commands Not Run

The commands to run in a K-enabled environment are:

```sh
kompile fvk/mini-model-form.k --backend haskell
kast --backend haskell fvk/construct-instance-spec.k
kprove fvk/construct-instance-spec.k
```

Expected machine-check result if the constructed proof is accepted: `#Top` for
all claims.

## Proof Sketch

The mini semantics models `construct_instance()`'s per-field decision as
`decide(field(...)) => Action`.

Eligibility rules rewrite to `skip` before the default-preservation rule:
non-editable fields, `AutoField`s, absent `cleaned_data` fields, fields not
allowed by `fields`, and fields excluded by `exclude` all match skip rules. The
`CI-INELIGIBLE-*` claims cover those filters. This proves PO-6 and frames the V1
edit as occurring only after existing filters.

The default-preservation rule is:

```k
decide(field(N, true, false, true, true, false, true, true, true, FILE, V))
  => skip
```

This exactly represents `hasDefault && omittedFromData && cleanedEmpty`, proving
PO-2.

The normal assignment rule is guarded by:

```k
requires notBool (DEF andBool OMIT andBool EMP)
```

For PO-1, substitute `DEF=true`, `OMIT=true`, and `EMP=false`. The guard reduces
to `notBool(false)`, so the action is `assign(some_field, nonEmpty)`.

For PO-3, substitute `DEF=true`, `OMIT=false`, and `EMP=true`. The guard again
reduces to `notBool(false)`, so submitted blank and non-omitted widget cases
assign instead of preserving the default.

For PO-4, substitute `DEF=false`. The guard reduces to `notBool(false)`, so
non-default fields are outside the default-preservation skip.

The file-field rule uses the same guard as normal assignment but returns
`queueFile(N, V)`. For PO-5, substituting `DEF=true`, `OMIT=true`, and
`EMP=false` reaches `queueFile(file_field, nonEmpty)`, representing append to
`file_field_list` and the later unchanged save loop.

No loop circularity is needed in the mini model because the audited property is
the independent decision for a single field. The source loop over `opts.fields`
is finite metadata traversal; V1 does not change its bounds, mutation of the
field list, or iteration order. The frame condition is that the per-field
decision is applied to each field and file actions are deferred, captured by
PO-5 and PO-6.

## Adequacy Check

`FORMAL_SPEC_ENGLISH.md` paraphrases each K claim. `SPEC_AUDIT.md` marks the
claims for PO-1 through PO-7 as pass against public intent. PO-8 is explicitly
not encoded because it is an ambiguity, not a public obligation.

## Test-Redundancy Recommendation

Recommendation-only and conditioned on a future successful `kprove` run:

- Tests asserting ordinary omitted empty default preservation are covered by
  PO-2 but should be kept until the machine check is run, because they also
  exercise Django integration outside the mini model.
- Tests asserting submitted blank values bypass defaults are covered by PO-3
  but should be kept until the machine check is run for the same integration
  reason.
- A new public regression test for the issue would be useful: a ModelForm that
  derives a non-empty value in `clean()` for an omitted defaulted field should
  save that derived value. The proof covers this as PO-1, but no test files were
  modified by instruction.

No tests were removed or edited.

## Residual Risk

The proof is partial correctness for the abstract field-decision relation. It
does not prove full Python/Django semantics, database behavior, form validation
termination, or test integration. It is intentionally constructed, not
machine-checked.
