# Spec Audit

Status: constructed, not machine-checked.

## GET-INLINES-DEFAULT

Audit result: pass.

The formal claim says the default hook returns `self.inlines`. This is entailed
by E-004 and preserves the old default behavior.

## GET-INLINE-INSTANCES-HOOK

Audit result: pass.

The formal claim says `get_inline_instances()` calls `get_inlines(request, obj)`
for inline class selection. This matches E-001, E-002, and E-003.

## GET-INLINE-INSTANCES-PRESERVE-FILTER

Audit result: pass.

The formal claim keeps construction and permission filtering unchanged. This is
entailed by E-002 because the public issue asks to avoid copying the loop, not
to change the loop semantics.

## TO-FIELD-ALLOWED-FRAME

Audit result: pass after V2 revision.

V1 changed this path to call `admin.get_inlines(request)` without an object.
That was candidate-derived and not required by the public issue. E-005 supports
preserving static `admin.inlines`; V2 restores that frame condition.

## CHECKS-FRAME

Audit result: pass.

The public issue asks for request/object-dependent inline selection. Checks run
without request/object context, so keeping static checks is compatible with
E-006.
