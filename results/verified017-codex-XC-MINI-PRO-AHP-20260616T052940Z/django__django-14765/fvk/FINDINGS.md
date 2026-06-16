# FINDINGS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F1: Pre-fix non-set conversion is removed by V1

- Classification: code bug resolved by V1.
- Evidence: ledger `L1` and `L2`; proof obligation `PO3`.
- Input: `ProjectState(real_apps=["contenttypes"])`.
- Observed before V1: the constructor converted the list to
  `{"contenttypes"}`.
- Expected from public intent: because `real_apps` is non-`None` and not a set,
  the constructor should assert that the contract was violated.
- V1 audit result: satisfied. `state.py:97` asserts
  `isinstance(real_apps, set)` before `state.py:98` assigns it.
- Recommended code action: none.

## F2: None remains the empty-set construction path

- Classification: boundary case confirmed.
- Evidence: ledger `L1`; proof obligation `PO1`.
- Input: `ProjectState(real_apps=None)` or omitted `real_apps`.
- Observed in V1: `state.py:94-95` assigns `self.real_apps = set()`.
- Expected from public intent: `None` is the only non-set sentinel allowed and
  should continue to produce an empty set.
- Recommended code action: none.

## F3: Empty set is now treated as a provided set

- Classification: boundary case confirmed.
- Evidence: ledger `L1`; proof obligation `PO2`.
- Input: `ProjectState(real_apps=set())`.
- Observed before V1: the falsy empty set took the old `else` branch and
  assigned a different newly-created empty set.
- Expected from "assert when non-None": even an empty set is non-`None`, so it
  should pass the type assertion and be assigned directly.
- V1 audit result: satisfied. `state.py:94` checks `is None`, not truthiness.
- Recommended code action: none.

## F4: External non-set callers are an intentional compatibility change

- Classification: compatibility decision, not a code bug.
- Evidence: ledger `L3`; proof obligations `PO3` and `PO5`.
- Input: external code calling `ProjectState(real_apps=("auth",))`.
- Observed before V1: tuple converted to `{"auth"}`.
- Expected from public issue: constructor may assume an internal normalized set
  contract and assert on non-`None` non-sets.
- Compatibility audit: source call sites found under `repo/django` pass `None`
  or a set-valued producer. Public docs mention `ProjectState` as a
  semi-internal migration-framework object but do not document the
  `real_apps` constructor argument as accepting arbitrary iterables.
- Recommended code action: none.

## F5: Proof is constructed only

- Classification: proof capability and environment limitation.
- Evidence: task forbids tests, Python, and K tooling; proof obligation `PO6`.
- Input: all formal claims in `fvk/projectstate-spec.k`.
- Observed: claims were written and reasoned about manually, but `kompile` and
  `kprove` were not run.
- Expected for machine verification: run the commands listed in
  `fvk/PROOF.md` and require `kprove` to return `#Top`.
- Recommended code action: none. Keep tests; do not remove any tests based on
  this constructed proof alone.

