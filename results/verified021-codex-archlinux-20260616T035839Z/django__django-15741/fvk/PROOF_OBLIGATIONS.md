# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Lazy-string equivalence

For every string `S`, `get_format(Promise(S), lang, use_l10n)` must follow the
same observable result family as `get_format(S, lang, use_l10n)`.

Evidence: E-001. Findings: F-001. K claims: C-001 through C-006.

Status: discharged by V1 because `Promise` is converted to `str` before branch
resolution.

## PO-002: No `Promise` reaches string-only `getattr()`

On all localized module lookup and settings fallback paths, the attribute name
passed to `getattr()` must be a concrete string when the original input was a
lazy string.

Evidence: E-003. Findings: F-001. K claims: C-002 and C-003.

Status: discharged by V1 because normalization occurs before both
`getattr(module, format_type, None)` and `getattr(settings, format_type)`.

## PO-003: Lazy arbitrary format fallback

If the normalized lazy string is not found in a localized module and is not a
registered format setting, `get_format()` must return that normalized string.

Evidence: E-002. Findings: F-001. K claims: C-001 and C-005.

Status: discharged by V1. The fallback `return format_type` now returns the
concrete string produced from the `Promise`.

## PO-004: Registered/custom format behavior is preserved

If the normalized lazy string names a localized module attribute or a registered
format setting, `get_format()` must use the same value that the concrete string
name would use.

Evidence: E-005 and E-006. Findings: F-001. K claims: C-002 through C-004.

Status: discharged by V1 because all membership and lookup checks operate on
the normalized string.

## PO-005: Non-Promise non-string frame condition

The fix must not rely on coercing every possible `format_type` to `str`.

Evidence: E-005 and E-007. Findings: F-003. K claim: C-007.

Status: discharged by V1 because the new coercion is guarded by
`isinstance(format_type, Promise)`.

## PO-006: Shared-helper compatibility

The repair must apply to `get_format()` itself without changing its public
signature or call protocol.

Evidence: E-001 and E-004. Findings: F-002. Compatibility audit:
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged by V1. The signature is unchanged and callers keep passing
the same arguments.

## PO-007: Honesty gate

The proof artifacts must be labeled constructed, not machine-checked, and no
test-removal recommendation may be treated as safe until `kprove` returns
`#Top`.

Evidence: FVK verify guidance. Findings: F-004.

Status: open as an execution constraint, not a source-code bug.
