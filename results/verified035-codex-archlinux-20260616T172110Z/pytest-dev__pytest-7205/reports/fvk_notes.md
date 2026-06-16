# FVK Notes

## Source changes after V1

Changed `repo/src/_pytest/setuponly.py` again after the FVK audit.

The V1 helper formatted non-string cached params with `saferepr`, but left raw
string params as unbounded bare strings. F-002 and PO-003 show that was weaker
than the public raw-param contract: setup-show should display raw fixture params
with bounded safe representation. V2 therefore moved `saferepr(request.param,
maxsize=42)` into the no-IDs branch of `pytest_fixture_setup`.

V2 also changed explicit ID handling. F-003 and PO-004 show that user-provided
string IDs are labels, not raw params, so blindly applying `saferepr` at write
time would over-change `ids=["spam"]` into a repr-style label. The new
`_format_fixture_id` preserves string IDs while PO-005 routes non-string IDs
through `saferepr` so bytes-like IDs cannot recreate the warning.

`_show_fixture_action` now writes `fixturedef.cached_param` directly. This is
justified by PO-001 and PO-002: after V2, the cached value is already a display
string for raw params or a formatted display label for explicit IDs. The writer
no longer needs to decide how to represent the original parameter object.

## Decisions to keep V1 behavior

Explicit string ID labels keep their V1 display shape. This is intentional and
traced to F-003 and PO-004.

The hook flow, capture suspension/resumption, dependency text, teardown display,
and deletion of `cached_param` are unchanged. This is traced to PO-006.

## Decisions not preserved

Raw string params no longer keep V1's bare-string display shape. F-004 marks the
old public-test expectation as SUSPECT for raw params because it conflicts with
the issue-derived bounded-safe-repr obligation in F-002 and PO-003. Test files
were not edited.

## Verification limits

Per F-005, no tests, Python, or K tooling were executed. The K proof is
constructed but not machine-checked. The exact commands are recorded in
`fvk/SPEC.md`, `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.
