# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO1: None branch

- Claim: if `real_apps is None`, `ProjectState.__init__()` succeeds and assigns
  `self.real_apps` to an empty set.
- Source: ledger `L1`.
- Code location: `repo/django/db/migrations/state.py:94-95`.
- Formal claim: `PROJECTSTATE-NONE` in `fvk/projectstate-spec.k`.
- Status: discharged by inspection of V1 and the constructed proof.

## PO2: Set branch

- Claim: if `real_apps` is a set, including an empty set, the assertion succeeds
  and the same set value is assigned to `self.real_apps`.
- Source: ledger `L1`.
- Code location: `repo/django/db/migrations/state.py:94-98`.
- Formal claims: `PROJECTSTATE-EMPTY-SET` and `PROJECTSTATE-NONEMPTY-SET`.
- Status: discharged by inspection of V1 and the constructed proof.

## PO3: Non-set non-None branch

- Claim: if `real_apps` is non-`None` and not a set, construction reaches
  `AssertionError` instead of converting the iterable to a set.
- Source: ledger `L1` and `L2`.
- Code location: `repo/django/db/migrations/state.py:96-98`.
- Formal claim: `PROJECTSTATE-NONSET-ASSERTS`.
- Status: discharged under normal Python assertion semantics. Python `-O`
  disables assertions; that is outside the assertion-based behavior requested
  by the issue.

## PO4: Successful-construction frame

- Claim: on successful construction, behavior of unrelated fields remains:
  `self.models = models or {}`, `self.is_delayed = False`, and
  `self.relations = None`.
- Source: ledger `L5`.
- Code location: `repo/django/db/migrations/state.py:91-101`.
- Formal claims: all successful claims in `fvk/projectstate-spec.k` include
  these cells.
- Status: discharged by inspection of V1 and the constructed proof.

## PO5: Source callsite compatibility

- Claim: source call sites in `repo/django` that reach
  `ProjectState(real_apps=...)` pass either `None` or a set.
- Source: ledger `L4`.
- Code locations:
  - `repo/django/db/migrations/graph.py:309` calls `ProjectState()` with
    `real_apps=None`.
  - `repo/django/db/migrations/graph.py:313` forwards `make_state()`'s
    `real_apps`.
  - `repo/django/db/migrations/loader.py:71` initializes
    `self.unmigrated_apps = set()`.
  - `repo/django/db/migrations/loader.py:338` passes that set producer.
  - `repo/django/db/migrations/executor.py:69` passes that set producer.
  - `repo/django/db/migrations/state.py:413` passes `self.real_apps`, already
    established by the constructor contract.
- Status: discharged by source inspection. No code change required.

## PO6: Machine-checking boundary

- Claim: FVK commands are emitted but not executed in this environment.
- Source: task constraints and FVK honesty gate.
- Commands: listed in `fvk/PROOF.md`.
- Status: open until run in an environment with K installed; not a blocker for
  confirming the source change because the relevant proof obligations are
  simple branch obligations and were manually constructed.

