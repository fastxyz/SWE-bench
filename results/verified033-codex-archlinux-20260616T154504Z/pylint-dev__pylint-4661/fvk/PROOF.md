# FVK Proof

Status: constructed, not machine-checked. The commands below were not run.

## Formal Core

- Semantics fragment: `fvk/mini-python-config.k`
- Claims: `fvk/pylint-config-spec.k`

Commands to machine-check later:

```sh
kompile fvk/mini-python-config.k --backend haskell
kast --backend haskell fvk/pylint-config-spec.k
kprove fvk/pylint-config-spec.k
```

Expected result after machine-checking: `#Top` for all claims.

## What Is Proved

Under the abstractions stated in `SPEC.md`, the V2 implementation satisfies:

- `PYLINTHOME` is an exact override.
- With no `PYLINTHOME`, a known home, and a valid absolute `XDG_CACHE_HOME`, the default is `XDG_CACHE_HOME/pylint`.
- With no `PYLINTHOME`, a known home, and no valid `XDG_CACHE_HOME`, the default is `$HOME/.cache/pylint`.
- With no `PYLINTHOME` and no known home, the fallback is `.pylint.d`.
- Missing selected directories are created recursively before stats are written.
- Public help and FAQ text now describe the same behavior.

## Proof Sketch

There are no loop circularities. The proof is a finite case split over environment state.

1. Case `HasPYLINTHOME == true`: the semantic rule for `resolveHome` rewrites directly to `PYLINTHOME`. This proves PO-1.
2. Case `HasPYLINTHOME == false` and `HOME == "~"`: `resolveHome` calls `defaultHome`, whose unknown-home rule rewrites directly to `.pylint.d`. This proves PO-4.
3. Case `HasPYLINTHOME == false`, `HOME != "~"`, and `XDGValid == true`: `defaultHome` rewrites to `join(XDG_CACHE_HOME, "pylint")`. This proves PO-2.
4. Case `HasPYLINTHOME == false`, `HOME != "~"`, and `XDGValid == false`: `defaultHome` rewrites to `join(join(HOME, ".cache"), "pylint")`. This proves PO-3.
5. Case `PathMissing == true`: `mkdirsIfMissing` records a recursive create effect for the selected path and returns the same path. This proves PO-5.
6. Case `PathMissing == false`: `mkdirsIfMissing` returns the same selected path without a create effect. This proves the frame condition for existing directories.

The prose frame obligations PO-6 through PO-9 are discharged by source inspection: `_get_pdata_path()` still prefixes with `PYLINT_HOME`, `base_name` sanitization is unchanged, no signatures changed, and V2 updates the FAQ wording found stale in F-004.

## Adequacy Gate

The English paraphrase of every formal branch is present in `FORMAL_SPEC_ENGLISH.md` and compared against public intent in `SPEC_AUDIT.md`. All required behaviors pass after the V2 FAQ update. The cache-vs-data choice is recorded as F-005 and resolved by the public hint that the stored files are non-crucial stats.

## Residual Risk

- The proof is constructed only; K was not run.
- `os.path.isabs` and `os.path.join` are modeled abstractly as validity and join operations, so the proof covers path-selection logic rather than every platform-specific path syntax.
- Windows-specific app-directory behavior is intentionally not specified by this proof.
- No test deletion is recommended without machine-checking, and no tests were edited.

