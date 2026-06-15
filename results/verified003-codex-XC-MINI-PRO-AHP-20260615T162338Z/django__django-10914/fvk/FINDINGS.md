# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
static source inspection, and constructed proof obligations only.

## F-001: Default `None` allowed path-dependent final file modes

- Classification: code bug in V0, fixed by V1/V2.
- Evidence: the issue reports that final uploaded file permissions can differ
  depending on whether the upload used `MemoryUploadedFile` or
  `TemporaryUploadedFile`.
- Concrete case: `source = temporary`, `tempMode = 0o600`, `memoryMode = umask
  result such as 0o644` with default `FILE_UPLOAD_PERMISSIONS = None`.
- Observed before the fix: `savedMode(temporary, none, 0o600, 0o644) = 0o600`
  while `savedMode(memory, none, 0o600, 0o644) = 0o644`.
- Expected by public intent: under default settings, both paths produce
  `0o644`.
- Resolution: `repo/django/conf/global_settings.py` now sets
  `FILE_UPLOAD_PERMISSIONS = 0o644`, which makes the existing `_save()` final
  `os.chmod()` path normalize both upload paths.
- Proof obligations: PO-001, PO-002, PO-003.

## F-002: Settings documentation must make final uploaded files the subject

- Classification: documentation clarity bug, improved in V2.
- Evidence: the issue says the old docs could be read as applying `0o600` only
  to temporary files that later disappear, while the actual concern is the file
  that ends up in the media directory.
- V1 wording: "files saved from temporary upload files" was accurate but still
  indirect.
- V2 resolution: `repo/docs/ref/settings.txt` now says "files uploaded through a
  temporary file will be saved with a mode of `0o600`" when the setting is
  explicitly `None`.
- Proof obligations: PO-004, PO-006.

## F-003: Directory permissions are intentionally out of the code change

- Classification: non-change decision, not a bug.
- Evidence: the public hint says there is no analogous inconsistency with
  directory permissions and that changes should not be needed to
  `FILE_UPLOAD_DIRECTORY_PERMISSIONS`.
- Resolution: V1/V2 leave `FILE_UPLOAD_DIRECTORY_PERMISSIONS = None`.
- Proof obligations: PO-005.

## F-004: Constructed proof is not machine-checked in this environment

- Classification: proof capability / environment boundary.
- Evidence: the task forbids running K tooling, tests, or Python.
- Impact: no test removal is recommended. The emitted `kompile`, `kast`, and
  `kprove` commands in `PROOF.md` are intended reproduction commands only.
- Resolution: artifacts are labeled "constructed, not machine-checked."

## Proof-Derived Findings From `/verify`

No additional code bug was found. The proof obligations show that once the
default setting is concrete, the storage-layer finalization rule is sufficient:
for both modeled upload paths, `savedMode(source, mode(420), tempMode,
memoryMode)` rewrites directly to `420`. The only V2 source edit after the FVK
audit is the documentation wording in F-002.
