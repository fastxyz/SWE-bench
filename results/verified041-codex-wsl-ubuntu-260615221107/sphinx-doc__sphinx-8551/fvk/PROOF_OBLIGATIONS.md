# Proof Obligations

Status: constructed, not machine-checked.

| ID | Claim | Public evidence | V1 discharge | Result |
| --- | --- | --- | --- | --- |
| O1 | Field xrefs copy `py:module` and `py:class` from current context. | E2, E8 | `PythonDomain.process_field_xref()` assigns both attributes from `self.env.ref_context`. | Discharged |
| O2 | `refspecific` is true only for leading-dot field targets; tilde-only targets do not trigger fuzzy lookup. | E2, E6, E9 | `PyXrefMixin.make_xref()` sets `refspecific` only when `target.startswith('.')`, while the existing `.` / `~` target-display rewrite remains. | Discharged |
| O3 | Plain field `A` in current module `mod` resolves to `mod.A` as a single target in the issue database, which has no top-level `A`. | E1, E2 | O1 gives `py:module = mod`; O2 gives searchmode 0; existing `find_obj()` reaches `mod + '.' + A` in the issue database. | Discharged |
| O4 | Plain field `A` in current module `mod.submod` resolves to `mod.submod.A` as a single target, not `mod.A`, in the issue database, which has no top-level `A`. | E1, E3, E4 | O1 gives `py:module = mod.submod`; O2 gives searchmode 0; existing `find_obj()` reaches `mod.submod + '.' + A` in the issue database. | Discharged |
| O5 | Plain field `A` with no module does not suffix-fuzzy resolve to `mod.A` or `mod.submod.A`. | E5 | O2 gives searchmode 0; with no exact top-level `A` and no module context, existing `find_obj()` returns no match. | Discharged |
| O6 | Leading-dot field `.A` still uses fuzzy/specific lookup. | E6 | O2 keeps `refspecific` for targets starting with `.`. | Discharged |
| O7 | Public APIs and call signatures remain compatible. | I6 | No signature changes; the Python domain implements an existing base hook. | Discharged |

## Open obligations

No code-correctness obligation is open for the issue scope. Machine checking is
not performed in this session, so the K artifacts remain constructed rather than
machine-verified.
