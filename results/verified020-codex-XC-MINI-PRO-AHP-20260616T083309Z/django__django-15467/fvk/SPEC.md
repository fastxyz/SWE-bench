# FVK Spec: Admin Radio ForeignKey empty_label

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Intent Spec

1. For a `ModelAdmin.formfield_for_foreignkey()` override that supplies
   `kwargs["empty_label"]` and then calls `super()`, the supplied value must not
   be replaced by the admin radio-field default when the field is blank.
2. If the admin chooses an `AdminRadioSelect` for a blank `ForeignKey` in
   `radio_fields` and no `empty_label` is supplied, the historical admin default
   label remains the translated `"None"`.
3. If the radio `ForeignKey` is not blank, the empty choice remains suppressed.
4. The fix must not change the `formfield_for_foreignkey()` public signature,
   dispatch shape, or queryset/widget behavior unrelated to the reported
   `empty_label` overwrite.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | `ModelAdmin drops my "empty_label" and set "default_empty_label"` | A caller-supplied `empty_label` must win over the admin radio default. | Encoded by C1 and PO1. |
| E2 | prompt | `kwargs['empty_label'] = "I WANT TO SET MY OWN EMPTY LABEL"` | The preservation obligation covers arbitrary custom labels, not only the exact example text. | Encoded by symbolic `L`. |
| E3 | prompt hint | `empty_label from kwargs should take precedence over _('None')` | Precedence is key presence in `kwargs` versus admin default. | Encoded by C1. |
| E4 | docs | `formfield_for_foreignkey` allows overriding the default formfield by modifying `kwargs` before `super()`. | The override mechanism is public API behavior and must remain compatible. | Encoded by PO5. |
| E5 | docs | `empty_label` can change the text, or `empty_label=None` can disable the empty label entirely. | Explicit falsy or `None` values are meaningful and must not be erased by a truthiness fallback. | Encoded by PO1 and finding F2. |
| E6 | code | `ModelChoiceField` sets `self.empty_label = None` for `RadioSelect` when `blank` is false. | Nonblank radio fields keep empty-choice suppression. | Encoded by C3 and PO3. |

## Formal Model

The formal core is an abstract mini-K model of the changed decision:

`resolveRadioEmptyLabel(blank, maybe_empty_label)`.

Labels are abstract values: `customLabel(S)`, `emptyStringLabel`,
`defaultNoneText`, and `noEmptyChoice`. `present(L)` means the `empty_label`
key is present in `kwargs`; `absent` means no key is present.

The concrete source line in `repo/django/contrib/admin/options.py` implements:

```python
kwargs["empty_label"] = (
    kwargs.get("empty_label", _("None")) if db_field.blank else None
)
```

## Claims

C1. `resolveRadioEmptyLabel(true, present(L)) => L` for every label `L`.

C2. `resolveRadioEmptyLabel(true, absent) => defaultNoneText`.

C3. `resolveRadioEmptyLabel(false, M) => noEmptyChoice` for every maybe-label
state `M`.

## Formal Spec English

C1 says that for a blank admin radio `ForeignKey`, any explicit `empty_label`
value already present in `kwargs` is passed through unchanged.

C2 says that for a blank admin radio `ForeignKey` without an explicit
`empty_label`, admin supplies the existing translated `"None"` default.

C3 says that for a nonblank admin radio `ForeignKey`, admin passes `None` for
`empty_label`, preserving the empty-choice suppression behavior.

## Spec Audit

| Claim | Adequacy result | Reason |
| --- | --- | --- |
| C1 | Pass | Directly matches E1, E2, E3, and E5. It is stronger than the issue's sample string because public docs make `None` meaningful. |
| C2 | Pass | Matches the preexisting default in the prompt when no custom value competes with it. |
| C3 | Pass | Matches documented/code behavior of nonblank radio `ModelChoiceField`; the issue only contests blank-field default overwrite. |

No claim depends on hidden tests, evaluator output, or original upstream patches.

## Public Compatibility Audit

The source change does not alter `formfield_for_foreignkey()`'s signature, call
sites, virtual-dispatch contract, return type, widget selection order, queryset
selection, or the final `db_field.formfield(**kwargs)` call. Existing overrides
that pass `empty_label` through `kwargs` become more compatible with the public
override pattern documented for `formfield_for_foreignkey()`.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-admin-empty-label.k --backend haskell
kast --backend haskell fvk/admin-radio-empty-label-spec.k
kprove fvk/admin-radio-empty-label-spec.k
```
