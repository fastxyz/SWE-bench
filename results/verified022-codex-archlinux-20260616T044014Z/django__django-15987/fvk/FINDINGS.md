# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: raw path-object comparison missed mixed Path/string duplicates

Classification: code bug fixed by V1.

Input:

`settings.FIXTURE_DIRS = [Path("/tmp/app/fixtures"), "/tmp/app/fixtures"]`

Pre-V1 observed behavior by source inspection:

The old code compared raw entries with `set(fixture_dirs)`. A `Path` object
and its equivalent string do not compare equal, so the duplicate check could
pass even though later fixture search would treat both entries as the same
filesystem path.

Expected behavior:

The existing duplicate `ImproperlyConfigured` error should be raised.

V1 status:

Resolved. V1 converts every configured entry with `os.fspath()` before the
existing duplicate check, so both entries become the same string before
`len(fixture_dirs) != len(set(fixture_dirs))` is evaluated.

Related proof obligations: PO-001, PO-002.

## F-002: realpath-level aliases are a plausible but underspecified broader case

Classification: underspecified intent / possible future hardening.

Input:

`settings.FIXTURE_DIRS = [Path("/tmp/app/../app/fixtures"), "/tmp/app/fixtures"]`

V1 observed behavior by source inspection:

V1 compares the two `os.fspath()` strings. If those strings differ, the
duplicate check does not raise at that point. The property later applies
`os.path.realpath()` to the final search list, which may collapse both entries
to the same directory.

Expected behavior:

Ambiguous from public evidence. The issue specifically names `Path` instances
and duplicate detection, and V1 handles equal filesystem strings across raw
types. The public evidence does not clearly require broadening this task to
all relative-path or symlink aliases.

V1 status:

Left unchanged. This finding blocks using realpath-level canonicalization as a
proof obligation for this issue, but it does not block V1 for the reported
Path/string duplicate defect.

Related proof obligations: PO-006.

## F-003: no public compatibility issue from the V1 mechanism

Classification: compatibility confirmation.

Input:

`settings.FIXTURE_DIRS = [Path("/tmp/project/fixtures_1")]` with no duplicate
and no app default fixture directory conflict.

Observed behavior by source inspection:

`os.fspath()` converts the entry to its string path and the existing code
continues through the same validation and search-list construction.

Expected behavior:

The path-like entry remains valid, matching existing public Path coverage.

V1 status:

Confirmed by proof obligation PO-004 and compatibility obligation PO-005.

## Proof-derived findings from `/verify`

No additional code bug was derived. The constructed proof only requires the
side condition already present in the V1 implementation: path-like entries
must be converted to filesystem strings before equality-based validation.

The proof is partial and constructed only. Machine checking would require the
commands listed in `PROOF.md`; this workspace instruction forbids running
them.
