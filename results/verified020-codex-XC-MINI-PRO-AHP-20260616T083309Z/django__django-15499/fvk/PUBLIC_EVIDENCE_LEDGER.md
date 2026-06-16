# PUBLIC EVIDENCE LEDGER

Status: constructed, not machine-checked.

See `fvk/SPEC.md` for the full ledger. Summary:

- E1: `benchmark/PROBLEM.md` requires `CreateModel + AlterModelManagers` to
  become a single `CreateModel`.
- E2: existing `CreateModel + AlterModelOptions` reduction supplies the local
  preservation pattern.
- E3: `AlterModelManagers.state_forwards()` passes `self.managers`.
- E4: `ProjectState.alter_model_managers()` assigns `list(managers)`.
- E5: same-model reductions use normalized model-name equality.
- E6: `CreateModel.__init__()` accepts empty manager lists through the `[]`
  normalization path.
