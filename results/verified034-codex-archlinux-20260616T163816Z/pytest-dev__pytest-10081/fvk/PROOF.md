# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` commands were run.

## What Is Proved

Against the mini semantics in `fvk/mini-unittest-pdb.k`, the V1 delayed-teardown condition satisfies the four claims in `fvk/pytest-unittest-pdb-spec.k`:

- class-level skipped unittest tests do not install or invoke delayed teardown;
- method-level skipped unittest tests do not install or invoke delayed teardown;
- synchronous non-skipped `--pdb` unittest tests still run real `tearDown` exactly once via pytest item teardown;
- synchronous non-skipped non-`--pdb` unittest tests keep normal teardown behavior.

## Proof Sketch

PO-001, class-level skip: Start from `run(USEPDB, ASYNC, METHOD_SKIPPED, true)` with `explicit = false` and `tdcount = 0`. The skip rule applies because `CASE_SKIPPED` is true. It rewrites to `finish` with `explicit = false` and leaves `tdcount = 0`. The `finish` rule for `explicit = false` terminates without incrementing `tdcount`. This proves the post-state `explicit = false`, `tdcount = 0`.

Mapped to V1 source, this is the path where `not _is_skipped(self._testcase)` is false, so the assignment to `_explicit_tearDown` is skipped. Since `_explicit_tearDown` remains `None`, `TestCaseFunction.teardown` has no saved user `tearDown` to call.

PO-002, method-level skip: Start from `run(USEPDB, ASYNC, true, CASE_SKIPPED)`. The same skip rule applies because `METHOD_SKIPPED` is true. It terminates through `finish` with `explicit = false` and `tdcount = 0`. This corresponds to the unchanged `not _is_skipped(self.obj)` conjunct in V1.

PO-003, non-skipped synchronous `--pdb`: Start from `run(true, false, false, false)`. The delayed-teardown rule applies and sets `explicit = true` without incrementing `tdcount`, modeling replacement of `self._testcase.tearDown` with a no-op during the unittest call. The `finish` rule for `explicit = true` then sets `explicit = false` and increments `tdcount` to `1`, modeling pytest item teardown invoking the saved original exactly once.

PO-003b, non-skipped synchronous no-`--pdb`: Start from `run(false, false, false, false)`. The non-delayed rule applies because `not USEPDB` is true; it leaves `explicit = false` and increments `tdcount` to `1`, modeling unittest's normal teardown path. `finish` with `explicit = false` terminates without an additional call.

## Adequacy Check

The English paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent-only obligations in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` marks each as PASS. The abstraction keeps the defect-discriminating observable: pre-V1 class-skip behavior yields a saved explicit teardown and final `tdcount = 1`; V1 yields no saved explicit teardown and final `tdcount = 0`.

## Residual Risk

This proof is partial and fragment-level. It does not machine-check the K claims, and it does not formalize the full Python interpreter, pytest runner, stdlib unittest internals, or async unittest behavior. These are recorded as F-005 rather than used as reasons for source changes.

## Machine-Check Commands

These commands are provided for a future environment. They were not run here.

```sh
kompile fvk/mini-unittest-pdb.k --backend haskell
kast --backend haskell fvk/pytest-unittest-pdb-spec.k
kprove fvk/pytest-unittest-pdb-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Test Recommendation

Do not remove any tests. The proof is constructed, not machine-checked, and the task forbids test edits. A useful public regression test, if test edits were allowed, would class-decorate a `unittest.TestCase` with `@unittest.skip`, define failing `setUp` and `tearDown`, run with `--pdb`, and assert one skipped test with no teardown error.
