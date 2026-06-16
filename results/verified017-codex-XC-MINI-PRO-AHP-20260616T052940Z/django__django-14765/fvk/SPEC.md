# SPEC: ProjectState real_apps Constructor Contract

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `ProjectState.__init__(models=None, real_apps=None)` in
`repo/django/db/migrations/state.py`, limited to the constructor behavior
affected by the issue: assignment of `self.real_apps` and preservation of the
unchanged constructor fields around it.

There are no loops or recursion in this unit, so the FVK proof has function
reachability claims only.

## Public Intent Ledger

### L1: Prompt Requires Set Assumption

- Source: prompt.
- Evidence: "ProjectState.__init__() can assume its real_apps argument is a set"
  and "it can just assert that it's a set when non-None."
- Semantic obligation: `real_apps` has two in-domain cases: `None`, and a
  Python `set`. `None` creates a fresh empty set. Any non-`None` value must pass
  an assertion that it is a set before being assigned to `self.real_apps`.
- Status: encoded by `PO1`, `PO2`, and `PO3`.

### L2: Remove Conversion Behavior

- Source: prompt.
- Evidence: "instead of checking that real_apps is a set and converting it to a
  set if not".
- Semantic obligation: a non-set iterable such as a list must not be silently
  converted with `set(real_apps)`.
- Status: encoded by `PO3`; finding `F1` records the pre-fix mismatch and V1
  resolution.

### L3: Internal API Assumption

- Source: prompt and public hint.
- Evidence: "Presumably the construction of new ProjectState objects is part of
  Django's internal API" and the hint's "Perhaps not this."
- Semantic obligation: changing behavior for external non-set constructor calls
  is compatible with this issue's accepted intent; the audit must still verify
  in-repository source call sites.
- Status: encoded by `PO5`; finding `F4` records the compatibility decision.

### L4: Source Producers of real_apps

- Source: implementation evidence.
- Evidence: `MigrationLoader.load_disk()` initializes `self.unmigrated_apps =
  set()`; `MigrationLoader.project_state()` passes it to graph `make_state()`;
  `MigrationExecutor._create_project_state()` passes it to `ProjectState`;
  `ProjectState.clone()` passes `self.real_apps`.
- Semantic obligation: known source call sites reaching the changed constructor
  branch supply either `None` or a set, so the new assertion does not break the
  source call graph.
- Status: encoded by `PO5`.

### L5: Constructor Frame

- Source: implementation evidence plus minimality of the task.
- Evidence: the issue concerns only `real_apps`; `models`, `is_delayed`, and
  `relations` are not mentioned as intended changes.
- Semantic obligation: V2 must leave `self.models = models or {}`,
  `self.is_delayed = False`, and `self.relations = None` unchanged on
  successful construction.
- Status: encoded by `PO4`.

## Function Contract

For every call to `ProjectState.__init__()` under normal Python assertion
semantics:

- If `real_apps is None`, construction succeeds and `self.real_apps` is a new
  empty set.
- If `real_apps` is a set, including an empty set, construction succeeds and
  `self.real_apps` is the provided set object.
- If `real_apps` is non-`None` and not a set, construction raises
  `AssertionError` at the assertion and does not silently convert the value.
- On successful construction, the unrelated constructor fields keep their
  pre-existing behavior: `models or {}`, `False`, and `None`.

## Formal Core

- Semantics fragment: `fvk/mini-python.k`.
- Claims: `fvk/projectstate-spec.k`.
- Human proof: `fvk/PROOF.md`.
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md`.

