# Public Compatibility Audit

Changed symbol:

- `django.forms.models.model_to_dict(instance, fields=None, exclude=None)`

Compatibility checks:

| Surface | Observation | Status |
| --- | --- | --- |
| Function signature | No parameters added, removed, or reordered. | Pass |
| Return type | Still returns a dictionary. | Pass |
| Direct callers | Direct calls with `fields=None` keep all editable fields except exclusions. | Pass |
| Empty-list callers | Direct calls with `fields=[]` now receive `{}` as required. | Pass |
| ModelForm initialization | `BaseModelForm.__init__()` passes `opts.fields` and `opts.exclude`; it benefits from the same corrected distinction. | Pass |
| Adjacent methods | `_save_m2m()` has a similar-looking truthiness check but is not a caller of `model_to_dict()` and has separate behavior. | No change |

No public override or virtual-dispatch compatibility issue is introduced because
the change is internal to `model_to_dict()` and does not alter dispatch shape.
