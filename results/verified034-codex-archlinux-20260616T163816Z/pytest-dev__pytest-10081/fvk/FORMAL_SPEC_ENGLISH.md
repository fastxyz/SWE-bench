# Formal Spec English

Status: constructed, not machine-checked.

K-CLAIM-CLASS-SKIP: For any `usepdb`, `async`, and method-skip flag, if the unittest `TestCase` instance/class is skipped, running the delayed-teardown fragment and then pytest item teardown ends with no saved explicit teardown and zero real `tearDown` calls from this fragment.

K-CLAIM-METHOD-SKIP: For any `usepdb`, `async`, and class-skip flag, if the collected unittest method is skipped, running the delayed-teardown fragment and then pytest item teardown ends with no saved explicit teardown and zero real `tearDown` calls from this fragment.

K-CLAIM-PDB-NONSKIPPED: For a synchronous, non-method-skipped, non-class-skipped unittest test with `--pdb`, pytest saves the original `tearDown`, unittest runs with the no-op replacement, and pytest item teardown later invokes the saved `tearDown` exactly once.

K-CLAIM-NO-PDB-NONSKIPPED: For a synchronous, non-skipped unittest test without `--pdb`, pytest does not save an explicit teardown; unittest's normal path accounts for one real `tearDown` call.

K-PRED-SHOULD-DELAY: The delayed teardown flag is true exactly when `usepdb` is true, the path is not async, the method is not skipped, and the `TestCase` instance/class is not skipped.

K-FRAME-COMPATIBILITY: The change does not alter method signatures, public node types, result callback methods, or pytest hook signatures.
