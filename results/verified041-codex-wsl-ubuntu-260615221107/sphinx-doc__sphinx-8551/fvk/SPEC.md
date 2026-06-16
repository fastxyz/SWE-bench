# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sphinx-doc__sphinx-8551`. The modeled
unit is the Python-domain field-xref path that produces and resolves the
reported references:

- `PyXrefMixin.make_xref()` for field-generated Python type references;
- `PythonDomain.process_field_xref()` as called by `Field.make_xref()`;
- the `resolve_xref()` search-mode decision through the issue database containing
  `mod.A` and `mod.submod.A`.

The model deliberately abstracts away docutils node tree details, HTML output,
intersphinx, built-in type suppression, and unrelated object kinds. It preserves
the bug-discriminating axis: context metadata, `refspecific`, and the selected
target or ambiguity.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: `:type:` and `:rtype:` should not differ from explicit Python roles in
  lookup behavior.
- E3/E4: under `py:currentmodule = mod.submod`, unqualified field type `A`
  resolves to `mod.submod.A` with no ambiguity warning.
- E5: in non-module scope, unqualified field type `A` must not silently fuzzy
  resolve to a suffix match.
- E6: `.` and `~` prefixes follow the explicit-role behavior.
- E7: legacy tests expecting no Python context on field refs are SUSPECT.

## Contract

For every field-generated Python reference in the supported target family:

1. `process_field_xref` copies current `py:module` and `py:class` onto the node.
2. Plain `A` is not `refspecific`.
3. `.A` is `refspecific` and displays/targets `A`.
4. `~mod.A` targets `mod.A`, displays `A`, and is not `refspecific`.
5. In the issue object database:
   - plain `A` under `mod` resolves to `mod.A`;
   - plain `A` under `mod.submod` resolves to `mod.submod.A`;
   - plain `A` with no module does not suffix-fuzzy resolve;
   - `.A` with no module retains suffix ambiguity.

## Formal Artifacts

- `mini-sphinx-xref.k`: mini-K semantics for field xref construction and the
  issue-specific resolver outcome.
- `sphinx-xref-spec.k`: K reachability claims for the obligations above.
- `FORMAL_SPEC_ENGLISH.md`: English paraphrase of each K claim.
- `SPEC_AUDIT.md`: adequacy comparison against intent.
- `PUBLIC_COMPATIBILITY_AUDIT.md`: API/callsite/subclass compatibility check.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-sphinx-xref.k --backend haskell
kast --backend haskell fvk/sphinx-xref-spec.k
kprove fvk/sphinx-xref-spec.k
```

Expected machine-check result after a K toolchain run: `#Top` for all claims.
