# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Class-Level Skip Suppresses Delayed Teardown

Claim: For all `USEPDB`, `ASYNC`, and `METHOD_SKIPPED`, if `CASE_SKIPPED` is true, then after `runtest` plus pytest item teardown, `tdcount = 0` and `explicit = false`.

Public evidence: E-001, E-002, E-003.

V1 discharge: `not _is_skipped(self._testcase)` is false when the `TestCase` instance/class has `__unittest_skip__`, so `_explicit_tearDown` is not set.

K claim: first claim in `fvk/pytest-unittest-pdb-spec.k`.

## PO-002: Method-Level Skip Suppresses Delayed Teardown

Claim: For all `USEPDB`, `ASYNC`, and `CASE_SKIPPED`, if `METHOD_SKIPPED` is true, then after `runtest` plus pytest item teardown, `tdcount = 0` and `explicit = false`.

Public evidence: E-004, E-006.

V1 discharge: unchanged from the pre-existing guard `not _is_skipped(self.obj)`.

K claim: second claim in `fvk/pytest-unittest-pdb-spec.k`.

## PO-003: Non-Skipped `--pdb` Teardown Still Runs Once

Claim: If `USEPDB = true`, `ASYNC = false`, `METHOD_SKIPPED = false`, and `CASE_SKIPPED = false`, then pytest saves the original teardown and real `tearDown` runs exactly once during pytest item teardown.

Public evidence: E-005, E-007.

V1 discharge: both skip conjuncts are true in negated form, so the delayed-teardown branch still executes.

K claim: third claim in `fvk/pytest-unittest-pdb-spec.k`.

## PO-003b: Non-`--pdb` Frame Remains Normal

Claim: If `USEPDB = false`, `ASYNC = false`, `METHOD_SKIPPED = false`, and `CASE_SKIPPED = false`, then pytest does not save an explicit teardown and unittest's normal path accounts for one real `tearDown` call.

Public evidence: E-002 and I-003.

V1 discharge: the edited branch is guarded by `self.config.getoption("usepdb")`, so the non-`--pdb` path is unchanged.

K claim: fourth claim in `fvk/pytest-unittest-pdb-spec.k`.

## PO-004: Instance Skip Predicate Reflects Class Skip

Claim: `_is_skipped(self._testcase)` is a valid representation of class-level unittest skip for this code path.

Public evidence: E-008, E-009 and default-domain assumption D-001.

V1 discharge: `_is_skipped` uses `getattr(obj, "__unittest_skip__", False)`, and existing local code calls `_is_skipped(self)` on unittest instances to suppress xunit setup/teardown.

## PO-005: Public Compatibility Frame

Claim: V1 does not change public API, public callback signatures, hook signatures, node type identities, or virtual dispatch shapes.

Evidence: source diff and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

V1 discharge: the diff only adds an internal Boolean conjunct in `TestCaseFunction.runtest`.

## PO-006: Honesty Gate

Claim: This proof is constructed, not machine-checked, and test removal is not justified.

Evidence: FVK `verify.md` honesty gate and task prohibition on running K tooling.

Commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-unittest-pdb.k --backend haskell
kast --backend haskell fvk/pytest-unittest-pdb-spec.k
kprove fvk/pytest-unittest-pdb-spec.k
```
