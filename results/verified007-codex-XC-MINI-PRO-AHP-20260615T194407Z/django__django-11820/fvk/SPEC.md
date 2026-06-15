# FVK SPEC: django__django-11820

Status: constructed, not machine-checked. Scope is limited to the production
code changed for this issue: `Model._check_ordering()`'s validation of
`Meta.ordering` entries that contain `LOOKUP_SEP`.

## Intent Spec

I1. A `Meta.ordering` path that traverses a related field and then names `pk`
must be valid when the relationship exists and the related model has a primary
key. Public evidence: `benchmark/PROBLEM.md` says `models.E015 is raised when
Meta.ordering contains __pk of a related field`, and reports that as the bug.

I2. Invalid ordering paths must still produce `models.E015`. Public evidence:
the issue quotes the error as the wrong result for a valid `related__pk` path,
not as an error class to remove for invalid fields. The existing checker's
purpose is to reject "the nonexistent field, related field, or lookup".

I3. `pk` is an alias only while resolving a model field path. Public evidence:
`Query.names_to_path()` maps `name == 'pk'` to `opts.pk.name` while walking
model options. After a concrete non-relational field is reached, remaining
parts are lookup/transform names, not model field names.

I4. Registered transforms on concrete fields remain valid ordering suffixes.
Public evidence: the in-repo invalid model checks include a public test pattern
that allows a registered lookup such as `test__lower`.

I5. The repair must preserve public API compatibility. The changed method is a
system-check helper; no public signature, return type, model option name, or
dispatch protocol should change.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`models.E015` is raised when `Meta.ordering` contains `__pk` of a related field" | Accept `related__pk` when the relation and related primary key exist. | Encoded by PO-1. |
| E2 | prompt | The quoted `models.E015` is the regression symptom. | Remove this error only for valid `related__pk`; keep errors for invalid paths. | Encoded by PO-2 and PO-3. |
| E3 | source | `Query.names_to_path()` rewrites `pk` to `opts.pk.name` during model-path resolution. | Mirror `pk` aliasing in the checker's model context. | Encoded by PO-1. |
| E4 | source | `names_to_path()` stops field traversal when a local non-relational field is reached; remaining names become transforms. | Do not rewrite `pk` after a scalar field; validate it as a transform. | Encoded by PO-3. |
| E5 | public tests/source | Registered lookup ordering such as `test__lower` is accepted. | A scalar-field suffix is valid when `get_transform()` accepts it. | Encoded by PO-4. |
| E6 | source/API | `_check_ordering(cls)` signature and error shape are unchanged. | No compatibility-impacting API change. | Encoded by PO-5. |

## Abstract Formal Model

The mini model abstracts Django's full model machinery to the pieces manipulated
by the fix:

- `C`: current model options context.
- `F`: previous resolved field, either `none`, `relation(TargetModel)`, or
  `scalar`.
- `parts`: the split ordering path.
- `pk(C)`: concrete primary-key field name for model `C`.
- `field(C, name)`: field lookup in model `C`.
- `transform(F, name)`: registered transform lookup for field `F`.
- `result`: `ok` or `e015(original_path)`.

Transition rules:

1. If `F` is `scalar` and there is another path part `p`, model-field traversal
   has ended. The checker must accept the part only when `transform(F, p)`
   exists; otherwise it returns `e015(original_path)`.
2. If `F` is `none` or `relation(_)`, the checker is still resolving a model
   field path. In this context only, `p == 'pk'` is rewritten to `pk(C)` before
   `field(C, p)` lookup.
3. If model-field lookup succeeds with a relation field, the next current model
   becomes that relation target.
4. If model-field lookup succeeds with a scalar field, later parts are governed
   by rule 1.
5. If model-field lookup fails in model context, the part is accepted only if it
   is a transform on the previous field; otherwise the checker returns
   `e015(original_path)`.

The constructed K core is in `fvk/mini-django-ordering.k` and
`fvk/model-ordering-spec.k`.

## Formal Spec English

C1. For a child model with a relation field `option` to model `Option`, and
`Option.pk.name == 'id'`, checking `option__pk` reaches `ok`.

C2. For a child model with a relation field `option` to model `Option`, checking
`option__missing` reaches `e015('option__missing')` unless the relation field has
a registered transform named `missing`.

C3. For a model with a concrete non-relational field `test`, checking
`test__pk` reaches `e015('test__pk')` unless the `test` field itself has a
registered transform named `pk`.

C4. For a model with a concrete non-relational field `test` that has a
registered transform `lower`, checking `test__lower` reaches `ok`.

C5. Non-related ordering entries, expression entries, random ordering marker
handling, direct `pk`, and error object shape remain governed by the surrounding
unchanged `_check_ordering()` code.

## Spec Audit

| Claim | Audit | Reason |
| --- | --- | --- |
| C1 | pass | Directly implements E1 and E3. |
| C2 | pass | Preserves E2 invalid-path behavior. |
| C3 | pass | Repairs the V1 over-acceptance found during FVK; follows E4. |
| C4 | pass | Preserves E5 transform behavior. |
| C5 | pass | Follows E6 and the unchanged code frame. |

No claim is supported solely by current candidate behavior. The only
implementation-derived facts are the state variables and helper operations that
the checker already uses.

## Public Compatibility Audit

No public symbol signature changed. `_check_ordering()` remains a classmethod
returning a list of Django check errors. The edit only changes how one internal
path-validation loop classifies split ordering components. No caller, subclass
override, or external option schema needs an update.
