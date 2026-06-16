# PROOF OBLIGATIONS

Status: constructed, not machine-checked.

PO1. No-dimension concrete registration.

- Precondition: `Abs = false`, `W = false`, `H = false`.
- Required postcondition: `Connected = false`.
- Evidence: `SPEC.md` E1, E2, E3.
- Candidate code: `if not cls._meta.abstract and (self.width_field or self.height_field):`.
- Status: discharged by symbolic evaluation of the guard.

PO2. Width-only concrete registration.

- Precondition: `Abs = false`, `W = true`, `H = false`.
- Required postcondition: `Connected = true`.
- Evidence: `SPEC.md` E4.
- Candidate code: same guard.
- Status: discharged by symbolic evaluation of the guard.

PO3. Height-only concrete registration.

- Precondition: `Abs = false`, `W = false`, `H = true`.
- Required postcondition: `Connected = true`.
- Evidence: `SPEC.md` E4, E8.
- Candidate code: same guard.
- Status: discharged by symbolic evaluation of the guard.

PO4. Both-dimensions concrete registration.

- Precondition: `Abs = false`, `W = true`, `H = true`.
- Required postcondition: `Connected = true`.
- Evidence: `SPEC.md` E4.
- Candidate code: same guard.
- Status: discharged by symbolic evaluation of the guard.

PO5. Abstract model non-registration.

- Precondition: `Abs = true`, any `W`, any `H`.
- Required postcondition: `Connected = false`.
- Evidence: `SPEC.md` E5.
- Candidate code: same guard preserves the pre-existing abstract-class
  condition.
- Status: discharged by symbolic evaluation of `not cls._meta.abstract`.

PO6. No-dimension update no-op equivalence.

- Precondition: `W = false`, `H = false`.
- Required postcondition: skipping the receiver causes no dimension-field state
  change compared with calling `update_dimension_fields()` and taking its early
  return.
- Evidence: `SPEC.md` E2, E3 and the existing guard inside
  `update_dimension_fields()`.
- Candidate code: receiver is not connected, and `update_dimension_fields()` is
  otherwise unchanged.
- Status: discharged as a frame/equivalence obligation.

PO7. Assignment-time update preservation.

- Precondition: `ImageFileDescriptor.__set__()` observes `previous_file is not
  None`.
- Required postcondition: `update_dimension_fields(instance, force=True)` is
  still called.
- Evidence: `SPEC.md` E6.
- Candidate code: descriptor code is unchanged by V1.
- Status: discharged by frame condition.

PO8. Public compatibility.

- Precondition: public code may construct `ImageField`, use width/height
  arguments, call descriptors, or observe signal behavior for dimension fields.
- Required postcondition: no public signature or expected dimension-maintenance
  path changes except removing the no-op no-dimension receiver.
- Evidence: `SPEC.md` I5 and compatibility audit.
- Candidate code: only the registration guard changes.
- Status: discharged by source inspection.

PO9. Machine-checking honesty.

- Precondition: benchmark forbids running Python, tests, or K tooling.
- Required postcondition: proof artifacts must be labeled constructed, not
  machine-checked, and test removal must not be recommended as completed.
- Evidence: user task and FVK verify honesty gate.
- Status: discharged by artifact labeling and by not running commands.
