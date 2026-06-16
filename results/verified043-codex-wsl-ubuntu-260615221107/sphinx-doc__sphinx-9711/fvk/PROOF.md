# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims Proved In This Construction

The constructed proof covers PO-001 through PO-009 in
`fvk/PROOF_OBLIGATIONS.md`. It proves partial correctness for the
`needs_extensions` check over finite requirement maps: if the function returns,
it respects version ordering for documented valid version strings and preserves
the existing non-comparison branches.

## Helper Proof

Target:

```python
def _is_version_requirement_satisfied(required: str, loaded: str) -> bool:
    try:
        return Version(loaded) >= Version(required)
    except InvalidVersion:
        return loaded >= required
```

Case 1: both strings are valid versions.

`Version(loaded)` and `Version(required)` both construct parsed version values,
so no `InvalidVersion` is raised. The `try` body returns exactly
`Version(loaded) >= Version(required)`. This discharges PO-001.

Concrete witness: `Version('0.10.0') >= Version('0.6.0')`, so the helper
returns true. This discharges PO-002 and addresses F-001.

Case 2: at least one string is rejected by `Version`.

The `InvalidVersion` handler returns `loaded >= required`, exactly the
compatibility fallback stated in PO-003. This branch is outside the semantic
version-ordering domain and is recorded as F-002.

## `verify_needs_extensions` Proof

The function has one finite loop over `config.needs_extensions.items()`. The
proof is by induction over the remaining entries.

Base case: no remaining configured entries.

There is no possible raise from the loop body, so the function completes. This
is the base of PO-007.

Step case: one current entry `(extname, reqversion)` and a finite remainder.

Branch A: `app.extensions.get(extname)` is `None`.

The function logs the existing warning and continues to the remainder. By the
induction hypothesis, the remainder satisfies the same contract. This discharges
PO-004.

Branch B: extension version is `unknown version`.

The sentinel check occurs before helper use and raises `VersionRequirementError`.
This discharges PO-005.

Branch C: extension version is known, valid, and older than the required valid
version.

By PO-001, the helper returns false exactly when
`Version(loaded) < Version(required)`. The `not helper(...)` condition is true,
so the existing `VersionRequirementError` path is taken. This discharges
PO-006.

Branch D: extension version is known, valid, and equal to or newer than the
required valid version.

By PO-001, the helper returns true. The compound raise condition is false, and
the loop proceeds to the remainder. By the induction hypothesis, all remaining
satisfying entries complete. This discharges PO-007.

## Adequacy Check

`fvk/SPEC_AUDIT.md` maps each formal claim C-001 through C-010 back to intent
entries I-001 through I-007. The issue witness comes from public issue text,
not from V1 behavior. The fallback branch is intentionally not used as evidence
for semantic version ordering.

## Compatibility Check

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` finds no public signature, metadata shape,
or dependency break. This discharges PO-008 and supports F-003.

## Machine-Check Commands

These commands are emitted for later checking and were not run:

```sh
kompile fvk/mini-sphinx-version.k --backend haskell
kast --backend haskell fvk/needs-extensions-spec.k
kprove fvk/needs-extensions-spec.k
```

Expected result: `kprove` reduces the claims to `#Top`.

## Test Guidance

No tests were run or modified. Because the proof is constructed but not
machine-checked, no existing tests should be removed on this evidence alone.
Useful tests to keep or add in a normal development environment would cover:

- `0.10.0` accepted for a `0.6.0` or `0.6` minimum;
- an older valid version rejected;
- an equal valid version accepted;
- `unknown version` rejected;
- missing configured extension warns and continues.
