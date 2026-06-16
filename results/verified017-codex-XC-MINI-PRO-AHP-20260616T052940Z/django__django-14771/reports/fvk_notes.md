# FVK Notes

## Decision

V1 stands unchanged. The audit traced the reported failure to
`get_child_arguments()` omitting `sys._xoptions` from Python-executable relaunch
argvs, and V1 already adds those arguments before the module/script target.

## Trace to Findings and Obligations

- F-001 is the core bug: autoreload lost `-X utf8` on the ordinary `manage.py`
  relaunch path. PO-001 and PO-004 show V1 discharges it by reading
  `sys._xoptions` and adding the resulting arguments before `sys.argv`.

- F-002 required value-style `-X name=value` options to keep their values, not
  merely their keys. PO-002 shows V1 discharges this with the `value is True`
  split in `repo/django/utils/autoreload.py`.

- PO-003, PO-005, and PO-006 justify keeping V1's edit location unchanged:
  adding xoptions to the shared `args` prefix preserves warning options and
  applies to script, module, and script-entrypoint branches without separate
  branch edits.

- F-003 records the only representation assumption: V1 emits attached short
  option strings such as `-Xutf8`. SPEC_AUDIT marks this as a named CPython
  default-domain assumption, so it is not a reason to change source code in this
  pass.

- F-004 and PO-007 justify leaving the direct `.exe` fallback unchanged. That
  branch bypasses `sys.executable`, already cannot receive `-W` flags, and is
  outside the reported `python -X ... manage.py` path.

- PO-008 and PUBLIC_COMPATIBILITY_AUDIT show no public API, caller, return-shape,
  or dispatch compatibility issue.

- F-005 explains why no tests or K commands were run and why no test-removal
  recommendation is made.

## Code Changes in This Pass

No source files under `repo/` were changed during the FVK pass. The only new
files are FVK artifacts under `fvk/` and this report.
