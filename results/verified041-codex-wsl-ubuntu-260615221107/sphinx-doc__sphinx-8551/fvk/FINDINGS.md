# FVK Findings

Status: V1 confirmed for the issue scope. No V2 source edit is justified by the
FVK audit.

## F1: Original false ambiguity and wrong target

- Classification: code bug fixed by V1.
- Evidence: E1-E4.
- Input: issue database contains `mod.A` and `mod.submod.A`; current module is
  `mod.submod`; field-generated type target is plain `A`.
- Pre-fix observed behavior: field xref had no `py:module` context and had
  `refspecific`, so resolver suffix search saw both `mod.A` and `mod.submod.A`
  and could pick `mod.A`.
- Expected behavior: one target, `mod.submod.A`, with no false ambiguity warning.
- Proof obligation: O1, O2, O4.
- V1 status: discharged.

## F2: SUSPECT legacy public test expectations

- Classification: suspect legacy evidence, not a source bug to preserve.
- Evidence: E7.
- Input: public in-repo `test_domain_py_xrefs` expected field-generated type refs
  under a current module to omit `py:module` and `py:class`.
- Observed legacy expectation: no Python context on `:type:` / `:rtype:` pending
  refs.
- Expected behavior from issue intent: field xrefs must carry context like
  explicit roles so unqualified names resolve relative to the current module.
- Proof obligation: O1.
- V1 status: V1 intentionally contradicts this stale expectation. No test file
  was edited.

## F3: Non-module-scope silent suffix link

- Classification: code bug fixed by V1.
- Evidence: E5, E9.
- Input: issue database contains only module-qualified `*.A` objects; current
  Python module is absent; field-generated type target is plain `A`.
- Pre-fix observed behavior: unconditional `refspecific` let resolver fuzzy
  suffix-search and silently link to a module-qualified `A` when only one suffix
  existed.
- Expected behavior: ordinary `A` outside module scope must not fuzzy-resolve;
  it remains unresolved for normal missing-reference handling.
- Proof obligation: O2, O5.
- V1 status: discharged.

## F4: Prefix behavior preserved

- Classification: frame condition / overcorrection guard.
- Evidence: E6.
- Input: field-generated target `.A` or `~mod.A`.
- Expected behavior: `.A` keeps `refspecific`; `~mod.A` shortens display and
  strips the target prefix without fuzzy lookup.
- Proof obligation: O2, O6.
- V1 status: discharged.

## Proof-derived findings from `/verify`

The constructed proof did not require a new side condition beyond the public
intent. No adequacy failure, compatibility failure, or unmodeled issue
contributor was found.

Residual risk: the proof is constructed but not machine-checked; no tests or K
commands were run.
