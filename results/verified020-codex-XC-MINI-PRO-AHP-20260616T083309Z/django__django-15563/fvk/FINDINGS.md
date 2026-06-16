# Findings

Status: constructed, not machine-checked.

## F1: V1 Addresses The Reported Wrong-Parent-Row Update

Input shape: `Child(Base, OtherBase)` queryset update where `field_otherbase` is
declared on `OtherBase`, child/base primary keys are `[1, 2]`, and the linked
`OtherBase` parent IDs are a different list such as `[3, 4]`.

Observed in pre-fix behavior from the issue: `OtherBase` rows with primary keys
`[1, 2]` are updated, while the `Child` rows' linked `OtherBase` values are not.

Expected: the related `OtherBase` update filters with `[3, 4]`, the parent-link
IDs for the selected `Child` rows.

Status: fixed by V1. This discharges PO1, PO2, and PO7.

## F2: Direct-Only Parent Link Selection Would Be Incomplete

Input shape: a deeper concrete MTI child updates a field declared on an indirect
ancestor.

Potential wrong implementation: use only `get_ancestor_link(model)` or only the
child primary key. For indirect paths through a child that has multiple concrete
parents, this can select the wrong immediate link and lose the target ancestor's
own parent-link ID.

Expected: use the full path from queryset model to target ancestor, ending in the
target parent-link `attname`.

Status: V1 uses `Options.get_path_to_parent()` and the final `join_field.attname`,
so no additional source change is required. This supports PO1.

## F3: No Public Compatibility Finding

Input shape: existing public callers of `QuerySet.update()` and internal callers
of `get_related_updates()`.

Observed in V1: public signatures and return shapes are unchanged; `related_ids`
is private internal state.

Expected: preserve public API while fixing the target row identifiers.

Status: no code change required. This discharges PO6.

## F4: Constructed Proof Not Machine-Checked

Input shape: all proof obligations in `update-related-ids-spec.k`.

Observed: K commands were written but not run, per task constraints.

Expected before deleting tests or claiming machine verification: run the emitted
`kompile` and `kprove` commands and receive `#Top`.

Status: residual verification caveat, not a code bug.

## Proof-derived findings from `/verify`

No proof-derived code bug was found. The adequacy audit passes for the stated
intent, and every proof obligation has a corresponding V1 mechanism. The only
remaining work is optional machine-checking of the constructed K artifacts and
adding public regression tests in the Django suite outside this benchmark task.
