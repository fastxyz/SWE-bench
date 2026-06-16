# SPEC.md

Status: constructed, not machine-checked.

## Scope

This FVK pass audits `pylint.modify_sys_path()` after the V1 patch. The function
has no loops and no return value; its observable behavior is mutation of
`sys.path`.

The mini semantics models the relevant state as:

- `PATHS`: finite list of path strings representing `sys.path`;
- `CWD`: exact `os.getcwd()` string;
- `ENV`: an `EnvCase` abstraction of the `PYTHONPATH` branch selected by the
  implementation.

`EnvCase` is property-complete for this bug because the implementation only
observes whether `PYTHONPATH` starts with `":"`, ends with `":"`, and whether
the special explicit `cwd` or `"."` exceptions apply.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. The key obligations
are:

- E1/E2/E3: non-CWD first entries are caller-owned and must be preserved.
- E3/E4: first entries equal to `""`, `"."`, or `cwd` may be removed.
- E5/E6: documented `PYTHONPATH` edge-colon cleanup and explicit-CWD
  exceptions remain part of the contract.
- E7: later CWD-like entries are not globally removed.
- E8: public tests are compatibility evidence for the existing documented
  `PYTHONPATH` cases, not an oracle for the reported pre-fix bug.

## Contract

For every finite `PATHS` and exact `CWD` in the modeled domain:

1. If `PATHS[0]` exists and is not `""`, `"."`, or `CWD`, then the result keeps
   that first element.
2. If `PATHS[0]` exists and is `""`, `"."`, or `CWD`, then the result removes
   that first element.
3. In leading implicit-`PYTHONPATH` cases, the extra CWD-like entry is removed
   from the slot immediately after the first-entry decision.
4. In trailing implicit-`PYTHONPATH` cases, the extra CWD-like entry is removed
   from the trailing startup slot after the first-entry decision.
5. In explicit `.` or explicit `cwd` `PYTHONPATH` edge cases, no extra
   `PYTHONPATH` cleanup occurs.
6. No rule removes later CWD-like entries outside the documented startup slots.

## Formal Artifacts

- `mini-python-syspath.k` defines the list-rewrite semantics for the reduced
  fragment.
- `modify-sys-path-spec.k` defines K claims for the obligations above, with
  provenance comments.

Run commands to machine-check later, not executed in this session:

```sh
cd fvk
kompile mini-python-syspath.k --backend haskell
kast --backend haskell modify-sys-path-spec.k
kprove modify-sys-path-spec.k
```

Expected result after a real machine check: `kprove` returns `#Top` for all
claims.
