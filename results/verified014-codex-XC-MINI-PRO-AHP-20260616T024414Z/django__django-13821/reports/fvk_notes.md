# FVK Notes

## Decisions and Traceability

1. Kept the V1 runtime guard change in
   `repo/django/db/backends/sqlite3/base.py`.

   - Trace: `fvk/FINDINGS.md` F-001; `fvk/PROOF_OBLIGATIONS.md` PO-001 and
     PO-002.
   - Reason: the public issue requires rejecting SQLite `< 3.9.0` while still
     accepting 3.9.0 and later. V1's threshold and error message satisfy those
     obligations.

2. Kept the V1 introspection comment cleanup in
   `repo/django/db/backends/sqlite3/introspection.py`.

   - Trace: `fvk/FINDINGS.md` F-001; `fvk/PROOF_OBLIGATIONS.md` PO-001.
   - Reason: after the support floor moves to 3.9.0, the old comment about
     pre-3.8.9 pragma output is stale. The runtime code remains unchanged.

3. Added V2 documentation updates in `repo/docs/ref/databases.txt` and
   `repo/docs/ref/contrib/gis/install/index.txt`.

   - Trace: `fvk/FINDINGS.md` F-002; `fvk/PROOF_OBLIGATIONS.md` PO-003.
   - Reason: FVK treats current public docs as intent evidence. V1 changed the
     runtime guard but left active docs advertising SQLite 3.8.3 support, which
     contradicted the new support floor. V2 updates those active support-floor
     statements to 3.9.0 / 3.9.0+.

4. Left historical release notes unchanged.

   - Trace: `fvk/PROOF_OBLIGATIONS.md` PO-003.
   - Reason: the obligation is to update active current support declarations.
     Old release notes that say prior Django releases raised the floor to 3.8.3
     remain historical facts, not current support promises.

5. Left JSON1 feature detection unchanged.

   - Trace: `fvk/FINDINGS.md` F-003; `fvk/PROOF_OBLIGATIONS.md` PO-004.
   - Reason: the issue describes `SQLITE_ENABLE_JSON1` as a compile-time option.
     Therefore SQLite 3.9.0+ is not enough by itself to guarantee JSON support;
     Django still needs the runtime `SELECT JSON(...)` probe.

6. Did not add expression-index API support.

   - Trace: `fvk/FINDINGS.md` F-004; `fvk/PROOF_OBLIGATIONS.md` PO-005.
   - Reason: this checkout's generic `Index` API is field-based and does not
     expose expression-index arguments. Adding a new API would exceed this
     support-floor fix.

## Verification Status

The FVK proof is constructed, not machine-checked. The K commands are recorded
in `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md` but were not executed, in
accordance with the task constraints. No tests, Python code, or K tooling were
run.
