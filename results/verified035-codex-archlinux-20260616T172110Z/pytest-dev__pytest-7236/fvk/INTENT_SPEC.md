# Intent Spec

Status: constructed from public evidence, before accepting V1 behavior as the
specification. This proof package is constructed, not machine-checked.

## Required Behaviors

I-1. A `unittest.TestCase` method skipped by `@unittest.skip` or equivalent
unittest skip metadata must remain skipped when pytest runs with `--pdb`.
For that skipped method, unittest does not run `setUp`, the test body, or
`tearDown`, and pytest must not run `tearDown` later through its delayed
`--pdb` mechanism.

I-2. For a unittest test method that reaches unittest's teardown phase while
`--pdb` is active, pytest may replace `tearDown` during the unittest call so
that postmortem debugging still sees the pre-teardown instance state, but the
real `tearDown` must be called later during pytest teardown.

I-3. Without `--pdb`, pytest must preserve the pre-existing behavior: no
pytest-delayed `tearDown` call is scheduled by this code path.

I-4. The fix must not change public APIs, test item signatures, or unittest
result callback signatures.

I-5. The proof target is partial correctness of the teardown scheduling state.
It does not prove full pytest execution, terminal output, PDB interaction,
process termination, or CPython's full unittest implementation.
