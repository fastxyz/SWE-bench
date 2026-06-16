# FVK Notes

## Decision

V1 stands unchanged. No additional Django source edit is justified by the FVK
audit.

## Trace to findings and proof obligations

FVK-F1 identifies the pre-V1 bug: `deconstruct()` compared evaluated
`self.storage` with `default_storage`, so callable storage returning
`default_storage` was omitted. O2 turns that into the primary proof obligation.

FVK-F2 shows V1 discharges O2. The selected value is now
`getattr(self, "_storage_callable", self.storage)`, so a callable returning
`default_storage` is compared and serialized as the callable, not as the
evaluated default storage.

FVK-F3 shows V1 discharges O3. The same local selection still omits storage for
implicit/default non-callable storage, preserving the normal default-value
deconstruction behavior.

FVK-F4 shows V1 discharges O4 and O5. Direct non-default storage remains
serialized as the storage object, and callable non-default storage remains
serialized as the original callable.

FVK-F5 and O6 justify making no further production-code change. The public
signature and deconstruction tuple shape are unchanged, `ImageField` continues
to inherit the corrected behavior through `super().deconstruct()`, and no
public callsite or override update is required.

O7 records the process constraint: tests, Python, and K tooling were not run.
The emitted K commands in `fvk/PROOF.md` are for later machine-checking only.
