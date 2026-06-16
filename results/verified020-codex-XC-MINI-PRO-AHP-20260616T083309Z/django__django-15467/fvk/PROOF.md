# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Theorem

For the admin radio `ForeignKey` branch in
`ModelAdmin.formfield_for_foreignkey()`, V1 satisfies the intended
`empty_label` precedence contract:

- explicit `kwargs["empty_label"]` values are preserved for blank radio
  foreign keys;
- the translated `"None"` default is used only for blank radio foreign keys
  without an explicit value;
- nonblank radio foreign keys still suppress the empty choice.

## Symbolic Cases

Case 1: `db_field.blank is True` and `empty_label` is present in `kwargs`.

The source expression evaluates the conditional's true branch:

```python
kwargs.get("empty_label", _("None"))
```

Because the key is present, dictionary lookup returns the stored value `L`. The
assigned value is `L`, which discharges PO1 and the claim
`resolveRadioEmptyLabel(true, present(L)) => L`.

Case 2: `db_field.blank is True` and `empty_label` is absent from `kwargs`.

The true branch is evaluated again, but dictionary lookup misses the key and
returns the default `_("None")`. The assigned value is the admin default, which
discharges PO2 and the claim
`resolveRadioEmptyLabel(true, absent) => defaultNoneText`.

Case 3: `db_field.blank is False`.

The conditional evaluates its false branch and assigns `None`, independent of
whether an `empty_label` key was present. This preserves the historical
nonblank-radio behavior and discharges PO3 and the claim
`resolveRadioEmptyLabel(false, M) => noEmptyChoice`.

Case 4: post-branch frame through queryset handling.

The later block may assign `kwargs["queryset"]`, but it does not read or write
`kwargs["empty_label"]`. By frame reasoning, the value established in cases 1-3
is the value passed into `db_field.formfield(**kwargs)`. This discharges PO4.

Case 5: public compatibility.

No call signature, override protocol, or return path changed. The fix only
changes the value assigned to an existing `kwargs` key in one branch. This
discharges PO5.

## Adequacy Result

The English meaning of the claims matches the public intent:

- The issue and public hint require `empty_label` from `kwargs` to take
  precedence over `_("None")`.
- Django forms docs make `empty_label=None` a valid explicit value, so the
  key-presence rule in V1 is the correct strengthening of the issue's suggested
  truthiness expression.
- The nonblank branch remains compatible with `ModelChoiceField` radio behavior.

No proof obligation remains that would justify a source change beyond V1.

## Commands Recorded But Not Run

```sh
kompile fvk/mini-admin-empty-label.k --backend haskell
kast --backend haskell fvk/admin-radio-empty-label-spec.k
kprove fvk/admin-radio-empty-label-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted:
`kprove` discharges the three claims to `#Top`. This expectation is not a test
result and was not used as evidence.

## Test Guidance

No test files were read as authoritative hidden evidence and no test files were
modified. Existing or future tests for the three symbolic cases above are
subsumed only after the recorded K commands are actually machine-checked.
Integration tests around admin rendering should be kept because the abstract
proof covers only this branch's `empty_label` value selection.
