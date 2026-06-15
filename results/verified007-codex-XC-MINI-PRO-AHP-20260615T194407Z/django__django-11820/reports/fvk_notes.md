# FVK Notes

## Decisions

V1 did not stand unchanged. `fvk/FINDINGS.md` F2 showed that V1 accepted
`test__pk` by applying the model `pk` alias after a concrete non-relational
field. `fvk/PROOF_OBLIGATIONS.md` PO-3 requires this to remain an error unless
`pk` is a registered transform on that scalar field. I changed
`repo/django/db/models/base.py` so once `fld` is a non-relation, subsequent
components are routed through the existing transform-check branch instead of
continuing model field lookup.

The original V1 idea of resolving `pk` for related model paths was kept.
`fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO-1 justify mapping `pk`
to `_cls._meta.pk.name` while validation is still in model/relation context.
This preserves the fix for `option__pk`.

The scalar-field guard also fixes the broader false negative in
`fvk/FINDINGS.md` F3: suffixes such as `test__id` should be transforms on
`test`, not model field lookups, unless the field actually registers such a
transform. This was accepted as in scope because it is the general rule needed
to satisfy PO-3 soundly.

No test files were modified. `fvk/ITERATION_GUIDANCE.md` lists focused tests to
add in a normal development environment, but the benchmark forbids editing tests
and running code.

## Artifacts

The requested FVK Markdown artifacts were written under `fvk/`:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK docs also require a formal core, so I added constructed K artifacts:

- `fvk/mini-django-ordering.k`
- `fvk/model-ordering-spec.k`

They are not machine-checked in this session. `fvk/PROOF.md` records the exact
commands for a future environment where K execution is allowed.
