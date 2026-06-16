# Formal Spec In English

Status: constructed, not machine-checked.

## C1: marked skip with runxfail

Starting from a makereport state where `runxfail` is true, no unittest
unexpected-success override is active, the report is a setup-phase skipped
report caused by a skip exception, and `skipped_by_mark_key` is true, execution
finishes with the same skipped outcome and the `longrepr` rewritten from the
internal skip site to the item skip site while preserving the reason.

## C2: unmarked skip with runxfail

Starting from the same runxfail skipped-report state but with
`skipped_by_mark_key` false, execution finishes without rewriting
`longrepr` to the item location.

## C3: xfail exception with runxfail

Starting from a call-phase skipped report caused by an xfail exception while
`runxfail` is true, execution finishes without setting `wasxfail` or otherwise
performing the xfail-specific report rewrite.

## C4: xfail exception without runxfail

Starting from a call-phase xfail exception while `runxfail` is false, execution
finishes with a skipped outcome and `wasxfail` set, preserving the pre-existing
normal xfail behavior.
