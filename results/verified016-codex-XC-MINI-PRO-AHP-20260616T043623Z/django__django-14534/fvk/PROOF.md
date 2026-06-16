# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Claims

The formal core is:

- `fvk/mini-django-boundwidget.k`
- `fvk/boundwidget-spec.k`

Claim `ID-FOR-LABEL-PRESENT`: if attrs contains `"id" |-> ID`, `idForLabel(attrs)` reaches `ID`.

Claim `ID-FOR-LABEL-ABSENT`: if attrs lacks `"id"`, `idForLabel(attrs)` reaches `""`.

Frame condition: no state is mutated.

## Constructed Proof

The audited Python property is:

```python
return self.data['attrs'].get('id', '')
```

Case 1, present id:

1. Precondition gives `self.data["attrs"]["id"] == ID`.
2. Python dictionary `get("id", "")` returns the stored value when the key exists.
3. The returned value is `ID`.
4. This matches `ChoiceWidget.create_option()`, which stores the rendered per-option id in `attrs["id"]`.
5. Therefore a custom `auto_id`, after being incorporated into the rendered option id, is preserved by `BoundWidget.id_for_label`.

Case 2, absent id:

1. Precondition gives no `"id"` key in `self.data["attrs"]`.
2. Python dictionary `get("id", "")` returns the default `""`.
3. The returned value is `""`.
4. Therefore the property does not invent a label target for a subwidget whose rendered markup has no id.

Frame:

1. The expression performs a dictionary read only.
2. No assignment or mutation occurs.
3. Parent widget and renderer state are not accessed by the property.

By case analysis, the property satisfies PC1 through PC3 in `fvk/SPEC.md`.

## Adequacy Check

The proof proves the intent-derived contract, not merely the V1 code as written:

- The present-id claim is anchored in the prompt's statement that `widget["attrs"]["id"]` is the id to use.
- The missing-id claim is anchored in the docs' "element's ID" wording and the templates' use of `widget.attrs.id`.
- The old generated fallback is rejected because it is the exact behavior reported as wrong for custom `auto_id`, and because it can expose an id not present in rendered markup.

## Proof-Derived Findings

No additional production-code defect was found.

F-002 remains an intentional behavior change relative to one public test: an option with no rendered id should not expose an invented id. This supports keeping V1 unchanged rather than adding a legacy fallback.

## Test-Redundancy Recommendation

No tests were modified.

After a real machine check, point tests that only assert present-id propagation for generated checkbox/radio option ids would be subsumed by `ID-FOR-LABEL-PRESENT`. Integration rendering tests should be kept because the mini-K proof does not cover the full Django renderer or template engine.

The existing select-option id expectation should be updated rather than retained, but the current task forbids test edits.

## Reproduce the Machine Check

These commands are emitted for a future environment with K installed. They were not run in this session.

```sh
kompile fvk/mini-django-boundwidget.k --backend haskell
kast --backend haskell fvk/boundwidget-spec.k
kprove fvk/boundwidget-spec.k
```

Expected machine-check result if the mini semantics and claims parse as written: `#Top`.

## Trusted Base and Residual Risk

This proof is partial correctness over a pure accessor; termination is immediate by inspection but not machine-proved.

Trusted base:

- adequacy of the mini-K abstraction for the property axis: present rendered id vs absent rendered id;
- source-level inspection that Django subwidget producers provide an `attrs` mapping;
- K toolchain and SMT behavior when the emitted commands are eventually run.

Residual risk is recorded as F-003.
