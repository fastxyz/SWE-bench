# FVK Notes

## Decisions

- Kept the V1 source change unchanged. This follows F-001 and PO-002 through PO-006: the `_known_functions` entries for `Max` and `Min` are enough to create dispatch methods, format builtin calls, and bypass `_print_not_supported`.
- Did not replace the mapping approach with explicit `_print_Min` and `_print_Max` methods. PO-003 and PO-005 show the existing generated-method mechanism proves the same behavior, and I-005 in `fvk/SPEC.md` identifies the mapping path as public-intent evidence.
- Accepted the `MpmathPrinter` inheritance side effect. F-003 and PO-007 classify it as compatible: public signatures do not change, user overrides still win, and NumPy keeps explicit vectorized methods.
- Did not edit tests. F-004 records missing plain-printer coverage, but the benchmark forbids modifying test files.
- Did not run tests, Python, or K tooling. F-002 and PO-008 record this as an environment/protocol boundary and provide the commands and expected `#Top` outcome for later machine checking.

## Source Changes During FVK

None. V1 remains the final code state.
