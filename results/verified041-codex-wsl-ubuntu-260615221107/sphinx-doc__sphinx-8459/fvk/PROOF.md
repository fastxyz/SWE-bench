# PROOF

Status: constructed, not machine-checked.

## Claims

The formal claims are in `autodoc-typehints-spec.k` and are paraphrased in
`FORMAL_SPEC_ENGLISH.md`.

* `CLAIM-RECORD-ALIASED-ANNOTATIONS` proves the V1 recording step stores the alias
  target for both parameter and return annotations.
* `CLAIM-MERGE-PRESERVES-RECORDED-ALIASES` proves description-mode field generation
  preserves the recorded alias string.
* `CLAIM-PREFIX-FAILS-ALIASED-ANNOTATIONS` identifies the pre-fix failing path as
  a negative finding.
* `CLAIM-NO-DUPLICATE-USER-FIELDS` preserves existing duplicate-prevention behavior.

## Constructed proof sketch

1. The public intent requires `JSONObject` to render as `types.JSONObject` in both
   signature and description modes.
2. In the Sphinx implementation, alias-aware rendering is performed by
   `sphinx.util.inspect.signature(subject, type_aliases=aliases)`, which resolves
   postponed annotations with the alias map before returning the signature object.
3. V1 changes `record_typehints()` to use that alias-aware helper call. Therefore,
   for the issue input, the signature object seen by the recorder has
   `data` and `return` annotations represented by the alias target string
   `types.JSONObject`.
4. The existing recorder then applies `typing.stringify()` to those annotations.
   `typing.stringify()` returns string annotations unchanged, so the stored values
   remain `types.JSONObject`.
5. `merge_typehints()` only runs when `autodoc_typehints == 'description'`; it
   passes the stored strings to `modify_field_list()`.
6. `modify_field_list()` inserts the stored `annotation` string directly into the
   generated paragraph body for `type data` and `rtype`, unless a user-provided field
   already exists. Thus the field output preserves `types.JSONObject`.
7. The pre-fix path lacked step 3's alias map and therefore allowed
   `JSONObject` to resolve to its underlying typing expression, matching the issue's
   rejected `Dict[str, Any]` output.

## Residual risk

This is a partial-correctness proof over a property-complete abstraction of the
autodoc typehint pipeline. It does not prove termination, full docutils tree
semantics, or the complete Sphinx build pipeline. No tests or K tooling were run.

## Commands to machine-check later

Do not run these in this benchmark session. They are recorded for a future environment
with K installed:

```sh
kompile fvk/mini-python-autodoc.k --backend haskell
kast --backend haskell fvk/autodoc-typehints-spec.k
kprove fvk/autodoc-typehints-spec.k
```

Expected machine-check result after a future run: `#Top` for all claims. Until then,
the proof remains constructed, not machine-checked.

## Test recommendation

Do not remove tests. The constructed proof suggests that a focused regression test for
`autodoc_typehints='description'` plus `autodoc_type_aliases` would be valuable, but
the task forbids modifying tests.
