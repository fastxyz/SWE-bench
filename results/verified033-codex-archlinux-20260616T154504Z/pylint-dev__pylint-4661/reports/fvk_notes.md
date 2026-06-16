# FVK Notes

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Decisions

1. Kept the V1 `pylint/config/__init__.py` behavior.

   - Traced findings: F-001 confirms the old `~/.pylint.d` default was the root bug; F-002 confirms absolute `XDG_CACHE_HOME` must be honored; F-003 confirms recursive creation is needed for nested XDG paths.
   - Traced obligations: PO-1 through PO-7 and PO-9 are satisfied by the V1 code. `PYLINTHOME` still overrides exactly, the default now uses XDG cache placement, `.pylint.d` remains only for unknown home directories, stats path construction is unchanged, and no public API signatures changed.
   - Result: no additional source-code edit was needed in `repo/pylint/config/__init__.py`.

2. Kept the cache-directory choice instead of switching to `XDG_DATA_HOME` / `~/.local/share/pylint`.

   - Traced finding: F-005 records the data-versus-cache ambiguity and resolves it using the public hint that the stored files are non-crucial stats.
   - Traced obligations: PO-2 and PO-3 require XDG cache placement for the selected default behavior.
   - Result: V1's `XDG_CACHE_HOME/pylint` or `$HOME/.cache/pylint` policy stands.

3. Updated `repo/doc/faq.rst`.

   - Traced finding: F-004 found that V1 left FAQ section 3.2 documenting the old `.pylint.d` fallback chain.
   - Traced obligation: PO-8 requires the public FAQ to describe the implementation's directory-selection order.
   - Change made: the FAQ now lists `PYLINTHOME`, absolute `XDG_CACHE_HOME/pylint`, `$HOME/.cache/pylint`, and current-directory `.pylint.d` only when the user home directory is not found.

4. Did not add dependencies or platform-specific Windows behavior.

   - Traced finding: F-005 resolves the specified issue with the standard-library XDG cache behavior; no finding requires a new dependency.
   - Traced obligation: PO-9 requires preserving public API shape and avoiding unnecessary compatibility churn. The Windows note in the public hint is treated as an open product question in `fvk/ITERATION_GUIDANCE.md`, not a specified requirement.

5. Did not edit tests.

   - Traced obligations: PO-9 and the benchmark instructions both require leaving the test suite unchanged.
   - Result: FVK suggests tests to add later in `fvk/ITERATION_GUIDANCE.md`, but no test file was modified.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- Formal/adequacy support files: `fvk/mini-python-config.k`, `fvk/pylint-config-spec.k`, `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

