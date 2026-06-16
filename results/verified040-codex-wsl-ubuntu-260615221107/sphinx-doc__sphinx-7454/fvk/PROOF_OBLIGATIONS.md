# FVK Proof Obligations for sphinx-doc__sphinx-7454

Status: constructed, not machine-checked.

## Obligations

PO-001, intent-derived.
For direct signature annotation text `None`, `_parse_annotation()` must produce
a Python pending reference with `refdomain="py"`, `reftarget="None"`, and
`reftype="obj"`.
Discharges findings: F-001, F-002.

PO-002, intent-derived.
Under an intersphinx inventory containing Python's documented `None` singleton,
the object-role `None` reference must be resolvable before the Python domain's
built-in fallback returns plain text.
Discharges findings: F-001.

PO-003, intent-derived frame condition.
For direct signature annotation text `int`, `_parse_annotation()` must continue
to produce a class-role pending reference so the prompt's working `int` link is
preserved.
Discharges findings: F-003.

PO-004, intent-derived frame condition.
For every annotation token `T` where `T != "None"`, V1 must leave role
selection as `reftype="class"`.
Discharges findings: F-003.

PO-005, branch coverage.
Both `_parse_annotation()` branches that call `make_xref()` must satisfy
PO-001 for exact text `None`: the normal parsed-text branch and the
`SyntaxError` fallback branch.
Discharges findings: F-004.

PO-006, consistency with description mode.
The signature-mode role for `None` must match the already existing
description-mode special case in `PyField` and `PyTypedField`, which changes
`target == "None"` from the class role to the object role.
Discharges findings: F-002.

PO-007, compatibility.
The patch must not change the Python function signature of `_parse_annotation()`,
the type shape `List[Node]`, public directive syntax, config values, event
signatures, or non-`None` annotation node text.
Discharges findings: F-005.

PO-008, honesty gate.
Because tests, Python execution, and K tooling are forbidden in this session,
the proof must remain labeled constructed, not machine-checked, and no tests may
be removed.
Discharges findings: F-006 and PF-002.

## Obligation-to-Claim Map

- C-001 in `fvk/SPEC.md` and `fvk/sphinx-7454-spec.k` discharges PO-001.
- C-002 discharges PO-004.
- C-003 discharges PO-002.
- C-004 discharges PO-003.
- PO-005 is discharged by the code fact that both parser paths call the same
  `make_xref()` helper modeled by C-001/C-002.
- PO-006 is discharged by matching the role choice already present in
  `PyField.make_xref()` and `PyTypedField.make_xref()`.
- PO-007 is discharged by source inspection of the V1 diff and call sites.
- PO-008 is discharged by recording, but not executing, the machine-check
  commands.
