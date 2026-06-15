# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep the V1 code behavior: `FILE_UPLOAD_PERMISSIONS = 0o644` is the correct
repair for the public issue, and no storage-layer algorithm change is needed.
The existing `FileSystemStorage._save()` final `os.chmod()` transition already
normalizes both upload paths once the setting is non-`None`.

Apply one V2 documentation improvement from F-002: make the settings docs say
that final files "uploaded through a temporary file" get the path-dependent mode
when `FILE_UPLOAD_PERMISSIONS = None`.

## Do Not Change

- Do not change `FILE_UPLOAD_DIRECTORY_PERMISSIONS`; PO-005 and the public hint
  say directory permissions do not have the reported inconsistency.
- Do not introduce a new sentinel or change the `FileSystemStorage` constructor
  signature. PO-007 requires public compatibility, and explicit global
  `FILE_UPLOAD_PERMISSIONS = None` already restores the previous behavior.
- Do not modify tests in this benchmark task.

## Next Verification Step Outside This Environment

Run the emitted K commands from `PROOF.md` in an environment with K installed.
Only after `kprove` returns `#Top` should anyone consider test-redundancy
cleanup, and even then only as a separate recommendation.

## Suggested Human Review Checklist

- Confirm `repo/django/conf/global_settings.py` has exactly
  `FILE_UPLOAD_PERMISSIONS = 0o644`.
- Confirm `repo/docs/ref/settings.txt` documents `Default: ``0o644``` and
  describes explicit `None` as OS-dependent final uploaded-file behavior.
- Confirm `repo/docs/howto/deployment/checklist.txt` no longer warns that the
  default upload settings produce inconsistent file modes.
- Confirm `repo/docs/releases/3.0.txt` notes the backwards-incompatible default
  change and the `None` restoration path.
