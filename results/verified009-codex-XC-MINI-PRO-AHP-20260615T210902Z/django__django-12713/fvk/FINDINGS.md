# FVK Findings: django__django-12713

Status: constructed, not machine-checked.

## F-001: Pre-fix widget overwrite in `formfield_for_manytomany()`

- Classification: code bug, resolved by V1.
- Evidence: prompt E-001 through E-003.
- Input: an auto-created many-to-many field whose name appears in `autocomplete_fields`, `raw_id_fields`, `filter_vertical`, or `filter_horizontal`, with `kwargs["widget"] = CustomWidget`.
- Observed before V1: `formfield_for_manytomany()` assigned `kwargs["widget"]` to the configured admin widget, overwriting `CustomWidget`.
- Expected: `CustomWidget` remains the widget passed to `db_field.formfield(**kwargs)`, matching `formfield_for_foreignkey()` precedence.
- V1 disposition: resolved by guarding admin widget selection with `if 'widget' not in kwargs:`.
- Proof obligation trace: OBL-001.

## F-002: V1 preserves default admin widget behavior when `widget` is absent

- Classification: confirmation / frame condition.
- Evidence: E-007.
- Input: an auto-created many-to-many field with no `widget` key and one of the admin widget configurations.
- Observed in V1: the same autocomplete/raw-id/filter/default widget branches execute because the new guard is true only when `widget` is absent.
- Expected: existing admin defaults remain available.
- V1 disposition: no additional source change required.
- Proof obligation trace: OBL-002.

## F-003: V1 preserves unrelated M2M formfield behavior

- Classification: confirmation / frame condition.
- Evidence: E-004 through E-006.
- Inputs: explicit or inferred queryset, `formfield_overrides`, and non-auto-created through models.
- Observed in V1: queryset handling, `formfield_overrides` merge precedence, and the non-auto-created through early return are unchanged.
- Expected: the widget fix does not alter these behaviors.
- V1 disposition: no additional source change required.
- Proof obligation trace: OBL-003, OBL-004, OBL-005.

## F-004: Public override compatibility remains intact

- Classification: compatibility finding, closed.
- Evidence: production override in `django.contrib.auth.admin.GroupAdmin` and docs examples all retain the `**kwargs` forwarding pattern.
- Observed in V1: method signature and caller dispatch shape are unchanged.
- Expected: existing overrides and callers remain compatible.
- V1 disposition: no additional source change required.
- Proof obligation trace: OBL-006.

## F-005: Proof and test-removal status

- Classification: proof caveat.
- Evidence: FVK instructions and task constraint prohibiting execution.
- Observed: K claims and proof were constructed, but `kompile`, `kast`, `kprove`, tests, and Python code were not run.
- Expected: do not claim machine-checked proof and do not remove tests.
- V1 disposition: keep tests untouched; source V1 may stand based on the constructed proof and static audit.
- Proof obligation trace: all obligations; see `fvk/PROOF.md`.
