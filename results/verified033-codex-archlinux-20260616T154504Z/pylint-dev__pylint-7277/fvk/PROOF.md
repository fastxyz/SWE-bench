# PROOF.md

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
command was executed in this session.

## What Is Proved

Under the reduced semantics in `mini-python-syspath.k`, the V1 implementation of
`modify_sys_path()` satisfies the obligations in `PROOF_OBLIGATIONS.md` for all
finite modeled `sys.path` lists, all exact `cwd` strings in the domain, and all
modeled `EnvCase` branches.

## Proof Shape

The function has no loops or recursion, so no circularity claim is needed.
Symbolic execution is bounded:

1. Classify whether the first item is CWD-like with `isCwdPath`.
2. Apply `removeSysPathEntry(PATHS, 0, CWD)`.
3. Case split on the `EnvCase`.
4. For implicit leading or trailing `PYTHONPATH` cases, use the boolean
   `firstRemoved(PATHS, CWD)` to choose the shifted startup slot.
5. Apply `removeSysPathEntry` only if the targeted slot is CWD-like.

The helper `removeSysPathEntry` is the central lemma:

- At index `0`, it deletes `ListItem(P)` exactly when `isCwdPath(P, CWD)` is
  true.
- At positive index `I`, it preserves the head and recurses on `I - 1`.
- On `.List`, it returns `.List`.

These rewrite rules preserve relative order and cannot delete a non-CWD path at
the targeted slot.

## Obligation Discharge

- PO-1 follows from the `notBool isCwdPath(FIRST, CWD)` branch of
  `removeSysPathEntry`.
- PO-2 follows from the `isCwdPath(FIRST, CWD)` branch.
- PO-3 follows from `modifyLeading`, which targets index `0` after first removal
  and index `1` when the first entry was preserved.
- PO-4 follows from `modifyTrailing`, which targets index `1` after first
  removal and index `2` when the first entry was preserved.
- PO-5 follows because `leadingExplicit` and `trailingExplicit` reduce to the
  same behavior as `noEdge`.
- PO-6 follows because no rule scans or filters the whole list.
- PO-7 is discharged by source inspection: the public function signature and
  call protocol are unchanged.

## Adequacy Gate

`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
`SPEC_AUDIT.md`, and `PUBLIC_COMPATIBILITY_AUDIT.md` are present. The audit
marks each formal claim as passing against public intent. No claim depends on a
hidden test, upstream fix, benchmark result, or legacy behavior contradicted by
the issue.

## Machine Check Commands

These commands are recorded for later use and were not run:

```sh
cd fvk
kompile mini-python-syspath.k --backend haskell
kast --backend haskell modify-sys-path-spec.k
kprove modify-sys-path-spec.k
```

Expected machine-check result after a valid K run: `kprove` returns `#Top`.

## Test Recommendation

No tests were edited. Existing public tests for `modify_sys_path` should be kept
unless the K proof is actually machine-checked. After machine-checking, the
covered public input-output cases in `tests/test_self.py::test_modify_sys_path`
would be candidates for redundancy review, but the runpy regression case should
still be represented as a public test if maintainers add one.

## Residual Risk

The result is a constructed proof over a reduced semantics. It does not claim
machine-checked confidence. It also intentionally treats CWD matching as exact
string equality, because that is the public issue's stated behavior.
