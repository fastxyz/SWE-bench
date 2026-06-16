# FVK Findings

Status: constructed, not machine-checked.

## F1 - Resolved: lowercased import path removed

Input: a Windows conftest path under a mixed-case package directory, such as
`C:\Azure\KMS\ComponentTest\Python\PIsys\conftest.py` or
`...\muepy\imageProcessing\wafer\sawStreets\tests\conftest.py`.

Observed in pre-fix code: `unique_path()` applied `normcase()` to the real path,
so `_importconftest()` passed a lowercased path to `pyimport()`. The issue shows
that this can produce `ModuleNotFoundError` for a lowercased package name such as
`python` or `muepy.imageprocessing`.

Expected by public intent: conftest import receives a canonical path with the
filesystem's real casing.

V1 status: fixed. `unique_path()` now uses `Path(str(path)).resolve()` and
returns `type(path)(...)`; there is no `normcase()` transition in the conftest
path flow.

Related proof obligations: PO-1, PO-2, PO-3.

## F2 - External obligation: filesystem/pathlib casing semantics

Input: an existing filesystem path whose spelling differs from the filesystem's
stored casing, or an existing path reached through a symlink.

Observed in V1 model: correctness depends on `Path.resolve()` returning a
canonical path string with filesystem casing preserved.

Expected by public intent: this is the exact mechanism suggested by the public
hint and by the helper docstring's "case-preserving" contract.

Classification: proof capability / trusted-base boundary, not a pytest
source-code bug. A complete machine proof would need a real Python plus Windows
filesystem semantics, or a verified specification of `Path.resolve()`.

Related proof obligations: PO-2, PO-4.

## F3 - Confirmed: conftest alias uniqueness preserved

Input: the same `conftest.py` discovered through a symlinked build directory or
through an alternate case spelling on a case-insensitive filesystem.

Observed in V1 model: both paths pass through the same canonicalization helper
before being used as `_conftestpath2mod` keys.

Expected by public intent: the source comment says realpath is used to avoid
loading the same conftest twice, and existing public tests cover symlink and
bad-case conftest loading.

V1 status: confirmed. Replacing `normcase(realpath)` with `Path.resolve()`
preserves canonicalization while avoiding lowercasing.

Related proof obligations: PO-4, PO-5.

## F4 - Confirmed: public compatibility preserved

Input: runtime callers and public tests that call `unique_path(path)`.

Observed in V1 model: the function still takes one argument and returns
`type(path)(canonical_string)`.

Expected by public intent: no caller or plugin should change for this bug fix.

V1 status: confirmed. No compatibility source edit is needed.

Related proof obligations: PO-1, PO-6.
