# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited source change is `repo/src/_pytest/pathlib.py::unique_path`.
The relevant consumers are the conftest paths in
`repo/src/_pytest/config/__init__.py`:

- `_set_initial_conftests()` for `_confcutdir`;
- `_getconftestmodules()` for directory-to-conftest module lists;
- `_importconftest()` for conftest cache keys and the path passed to
  `py.path.local.pyimport()`.

## Public Intent Ledger

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1/E2: the reported regression is a lowercased conftest path reaching import.
- E3: public hint says to avoid `os.normcase` and use a correct-casing resolver,
  with `Path.resolve()` named as the likely mechanism.
- E4/E5: mixed-case package path components such as `imageProcessing` are in
  domain and must remain mixed-case before import.
- E6/E8: conftest discovery must still canonicalize symlink/case aliases so the
  same conftest is not loaded twice.
- E7: the helper's own docstring promises a unique path for case-insensitive but
  case-preserving filesystems.
- E9: public compatibility requires preserving the one-argument API and returning
  the original path type.

## Contract

For any in-domain path object `p` naming an existing filesystem entry used by
conftest loading:

O1. `unique_path(p)` returns an object of `type(p)`.

O2. The returned path string is canonical for the filesystem entry named by `p`:
symlink aliases and case aliases of the same entry map to the same string.

O3. The returned path string preserves filesystem casing. It must not be the
result of lowercasing or `os.path.normcase()` on Windows.

O4. `_importconftest()` passes the case-preserving canonical path to
`pyimport()`, so module-name calculation sees `Python`, `PIsys`,
`imageProcessing`, and similar mixed-case components as stored on disk.

O5. The conftest cache-key behavior is preserved: the same real conftest file
reached through symlinks or case aliases has one key in `_conftestpath2mod`.

## Domain and Trusted Base

The specified domain is existing paths used by conftest loading. The source
already checks `conftestpath.isfile()` before import and the CLI validates
`--confcutdir` with `directory_arg`.

The proof relies on an external filesystem/path library axiom:
`Path(str(path)).resolve()` returns a symlink-resolved canonical string with
filesystem casing preserved for existing paths. This cannot be derived from the
mini semantics; it is recorded as PO-2 and FINDING F2.

## Formal Artifacts

- `fvk/mini-python-path.k` models the path-wrapper expression used by V1.
- `fvk/unique-path-spec.k` states the K claims and external filesystem
  simplification obligations.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims.
- `fvk/SPEC_AUDIT.md` checks the claims against this intent spec.
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` checks public call compatibility.

## V2 Decision

V1 stands unchanged. The FVK obligations identify no source-code gap beyond the
external `Path.resolve()` filesystem behavior, and V1 is exactly the source edit
that removes the intent-contradicting `normcase()` transition while preserving
canonicalization and return type.
