# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and symbolic reasoning. No tests or tools were run.

## F1: Pre-V1 UI exposed "Save as new" without add permission

Classification: code bug fixed by V1.

Input:

```text
is_popup = false
has_add_permission = false
has_change_permission = true
change = true
save_as = true
```

Observed before V1:

```text
show_save_as_new = true
```

Expected from public intent:

```text
show_save_as_new = false
```

Trace: I1 and I2 in `SPEC.md`; PO-1 in `PROOF_OBLIGATIONS.md`; K claim
`NO_ADD` in `submit-row-spec.k`.

Resolution: V1 adds `and has_add_permission` to the condition in
`admin_modify.py`, discharging the finding.

## F2: "Save as new" must still require change permission

Classification: confirmed requirement, no new source change needed.

Input:

```text
is_popup = false
has_add_permission = true
has_change_permission = false
change = true
save_as = true
```

Expected:

```text
show_save_as_new = false
```

Trace: I3 in `SPEC.md`; PO-2 in `PROOF_OBLIGATIONS.md`; K claim `NO_CHANGE`.

Resolution: V1 preserves the existing `has_change_permission` and `change`
requirements. The audit rejects the alternative "check only add permission".

## F3: Backend forged-POST guard is already present

Classification: no code bug found in the backend path.

Input:

```text
POST contains "_saveasnew"
request user lacks add permission
```

Observed in source:

```text
_changeform_view() sets object_id = None, then rejects the request when
has_add_permission(request) is false.
```

Expected:

```text
PermissionDenied before adding a new object.
```

Trace: I6 in `SPEC.md`; PO-7 in `PROOF_OBLIGATIONS.md`.

Resolution: no edit to `ModelAdmin._changeform_view()` is justified by this
issue.

## F4: Proof is constructed, not machine-checked

Classification: proof process limitation, not a source-code bug.

The K claims and proof sketch have not been run through `kompile` or `kprove`.
The source-code conclusion is based on the constructed proof obligations and
source inspection. Test removal is not recommended.
