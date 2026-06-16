# Public Evidence Ledger

## E-1

Source: `benchmark/PROBLEM.md` prompt.

Quote: "unittest.TestCase.tearDown executed on skipped tests when running --pdb"
and "I would have expected the test to be skipped, even with `--pdb`."

Semantic obligation: skipped unittest methods must not execute `tearDown`
through pytest's `--pdb` teardown deferral path.

Status: encoded by `SKIPPED-UNDER-PDB` and `PO-1`.

## E-2

Source: `benchmark/PROBLEM.md` reproduction.

Quote: normal `pytest test_repro.py` reports "1 skipped", while
`pytest --pdb test_repro.py` reports "1 skipped, 1 error" from `tearDown`.

Semantic obligation: the regression is specific to `--pdb`; the expected
outcome does not include a teardown error for a decorator-skipped method.

Status: encoded by `SKIPPED-UNDER-PDB`, `NO-PDB-NO-DELAYED-CALL`, `PO-1`,
and `PO-3`.

## E-3

Source: public hint in `benchmark/PROBLEM.md`.

Quote: "changes pdb, skip and teardown".

Semantic obligation: the relevant interaction is the conjunction of pdb mode,
unittest skip handling, and teardown deferral.

Status: used to select the modeled state variables: `usepdb`,
`unittestCallsTearDown`, `_explicit_tearDown`, and delayed teardown call count.

## E-4

Source: `repo/testing/test_unittest.py::test_pdb_teardown_called`.

Quote: the test states that pytest delays normal `tearDown` calls when `--pdb`
is given and asserts both passing unittest methods eventually append their ids
from `tearDown`.

Semantic obligation: V1 must not fix skipped tests by dropping delayed
teardown for tests that actually reach unittest teardown.

Status: encoded by `REACHED-TEARDOWN-UNDER-PDB` and `PO-2`.

## E-5

Source: comment in `repo/src/_pytest/unittest.py`.

Quote: "when --pdb is given, we want to postpone calling tearDown() otherwise
when entering the pdb prompt, tearDown() would have probably cleaned up instance
variables".

Semantic obligation: the delayed call exists to preserve debug visibility, not
to change whether unittest would call teardown.

Status: encoded by `REACHED-TEARDOWN-UNDER-PDB` and used in the adequacy check.

## E-6

Source: `repo/src/_pytest/runner.py::runtestprotocol` and `SetupState`.

Quote: after setup and call, pytest appends a teardown report and
`SetupState._teardown_with_finalization` calls `colitem.teardown()`.

Semantic obligation: if `_explicit_tearDown` is set when pytest teardown runs,
`TestCaseFunction.teardown` is the handoff point that invokes it.

Status: modeled by the `teardown` and `maybeCall` rules.
