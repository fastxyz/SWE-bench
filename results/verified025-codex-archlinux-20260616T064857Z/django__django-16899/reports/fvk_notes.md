# FVK Notes

## Decisions

V1's code change in `repo/django/contrib/admin/checks.py` stands. F-01 identifies
the original bug as the missing invalid field value in the `admin.E035` message,
and PO-01 through PO-04 are discharged by the V1 source change: the message now
interpolates `field_name`, still carries the indexed label, preserves the valid
no-error branches, and leaves `admin.E035` plus `obj=obj.__class__` unchanged.

The FVK audit did surface one improvement: F-02 says V1 left
`repo/docs/ref/checks.txt` documenting the old message shape. PO-05 requires the
public checks reference to match runtime behavior, so I updated the `admin.E035`
entry to say `readonly_fields[n]` refers to `<field name>`.

I did not edit tests. F-03 and PO-06 classify the visible tests asserting the old
message as SUSPECT legacy evidence because they encode the omission described by
the issue. The benchmark forbids test edits, so this remains documented guidance
rather than a test-file change.

## Verification status

The FVK artifacts are constructed, not machine-checked. I did not run tests,
Python, `kompile`, `kast`, or `kprove`; the commands are recorded in
`fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` for a future environment.
