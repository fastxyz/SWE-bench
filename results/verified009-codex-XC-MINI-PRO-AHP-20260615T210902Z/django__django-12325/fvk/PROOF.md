# PROOF

Status: constructed, not machine-checked. No tests, Python, `kompile`, or `kprove` were run.

## Proof Target

The proof targets the parent-link selection fragment of `ModelBase.__new__()`.

The mini semantics in `mini-django-parent-links.k` models the relevant field scan:

`collect(fields) -> parentLinksMap`

Only the properties needed for the issue are represented: field order, whether the field is a `OneToOneField`, the related model key, and the `parent_link` flag. This keeps the model property-complete for the defect axis while avoiding unrelated Django metaclass machinery.

## Claims

C1. `collect([explicit_parent_link, ordinary_o2o]) = {Parent: explicit_parent_link}`.

C2. `collect([ordinary_o2o, explicit_parent_link]) = {Parent: explicit_parent_link}`.

C3. `collect([ordinary_o2o]) = {}`.

C4. `collect([non_o2o]) = {}`.

The K claims are in `modelbase-parent-links-spec.k`.

## Constructed Proof Sketch

For C1, symbolic execution starts with `collect(FS)` and rewrites to `collectAcc(FS, .Map)`. The first field has `IsOneToOne == true` and `ParentLink == true`, so the explicit-parent rule updates the map at the parent key. The second field has `ParentLink == false`, so the ordinary-field rule leaves the map unchanged. The final `.Fields` rule returns the map containing the explicit field.

For C2, symbolic execution first sees the ordinary field and leaves the map unchanged. It then sees the explicit parent-link field and updates the map at the parent key. The final `.Fields` rule returns the map containing the explicit field. This proves ordinary-field order does not matter for the reported two-field cases.

For C3, symbolic execution sees a single ordinary one-to-one field, takes the ordinary-field rule, leaves the map unchanged, and returns `.Map`. This is the key V1 failure: V1 would still create a parent-link candidate for a bare ordinary field, but public intent requires no declared entry.

For C4, symbolic execution sees `IsOneToOne == false`, takes the non-one-to-one rule, leaves the map unchanged, and returns `.Map`.

The source-level proof obligation PO4 composes C3 with the existing Django code after the collection loop: if `base_key` is absent from `parent_links`, the pre-existing `elif not is_proxy:` branch creates the automatic parent pointer with `parent_link=True`.

## Machine-Check Commands Not Run

These commands are the recorded machine-check path for a later environment:

```sh
kompile fvk/mini-django-parent-links.k --backend haskell
kast --backend haskell fvk/modelbase-parent-links-spec.k
kprove fvk/modelbase-parent-links-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Residual Risk

This proof is partial and fragment-scoped. It proves the selection relation modeled by the K fragment and relies on source inspection for integration with the rest of Django class construction. It does not prove termination separately, but the modeled recursion structurally consumes a finite field list.

The proof is constructed, not machine-checked. Test removal is not recommended.

## Test Guidance

Add or keep tests that exercise:

- explicit parent link before ordinary one-to-one field to the same parent;
- ordinary one-to-one field before explicit parent link to the same parent;
- ordinary one-to-one field to parent with no explicit parent link, expecting auto-created parent pointer behavior rather than `ImproperlyConfigured`;
- abstract-base explicit parent-link discovery.

No tests were edited in this task.
