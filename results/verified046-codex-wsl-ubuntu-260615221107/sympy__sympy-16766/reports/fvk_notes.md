# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python code, or
K tooling.

## Decisions

### D-001: Keep V1 `_print_Indexed`

Decision: no change was made to V1's `_print_Indexed` implementation.

Trace:

- F-001 identifies the original bug: `Indexed` reached the unsupported fallback.
- PO-001 proves the output body for `IndexedBase("p")[0]` is `p[0]`.
- PO-003 proves index order and comma-space formatting for multi-index cases.
- PO-004 proves supported `Indexed` inputs no longer add `Indexed` to
  `_not_supported`.

Rationale: the implementation satisfies the public issue and the exact output
form requested by the issue hint.

### D-002: Keep V1 `_print_Idx`

Decision: no change was made to V1's `_print_Idx` implementation.

Trace:

- F-002 identifies the dependent case that would remain unsupported if only
  `_print_Indexed` were added.
- PO-002 proves `Idx(label)` renders as the label.
- PO-004 proves supported `Idx` inputs no longer add `Idx` to `_not_supported`.

Rationale: `Idx` is common in `Indexed` expressions, and rendering it as its
label matches `Idx._sympystr` in `repo/sympy/tensor/indexed.py`.

### D-003: Keep the method placement on `PythonCodePrinter`

Decision: V1 remains scoped to `PythonCodePrinter`; I did not move the methods
to `AbstractPythonCodePrinter`.

Trace:

- F-004 confirms compatibility.
- PO-005 proves the fix reaches `LambdaPrinter` through inheritance while not
  changing `TensorflowPrinter`, which inherits from the abstract base directly.

Rationale: the public issue names `PythonCodePrinter`, and this placement fixes
`pycode` and lambdify-oriented printing without widening the change to unrelated
printer families.

### D-004: Make no V2 source edits

Decision: the production source remains as V1.

Trace:

- F-001 through F-004 are resolved or confirmed.
- `FINDINGS.md` lists no open code findings.
- PO-001 through PO-005 are discharged by constructed proof.
- PO-006 is only the honesty gate for non-executed formal tooling.

Rationale: the audit found no concrete source defect to repair. Changing the
code further would be unrelated to the stated issue.

### D-005: Do not modify tests

Decision: no test files were modified.

Trace:

- PO-006 states test deletion is not justified without machine-checking.
- `PROOF.md` lists recommended future tests but does not classify any existing
  public test as safely removable.

Rationale: the task forbids modifying test files, and the constructed proof does
not license test removal.
