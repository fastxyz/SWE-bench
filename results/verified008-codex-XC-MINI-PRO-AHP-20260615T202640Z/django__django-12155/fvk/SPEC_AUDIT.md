# Specification Adequacy Audit

Status: constructed, not machine-checked.

| Formal Claim | Intent Coverage | Result |
| --- | --- | --- |
| C1 Empty Guard | Matches I1 and E10. Missing docstrings and all-whitespace docstrings must produce a string result. | Pass |
| C2 Non-Empty Dispatch | Matches I2, I3, E6, and E7. The non-empty path must use PEP 257 cleanup. | Pass |
| C3 PEP 257 Cleandoc Property | Matches I2, I3, I4, E4, E5, E6, and E7. It excludes the first line from the margin and handles the empty-tail case. | Pass |
| C4 First-Line Summary Directive Safety | Matches I2, I5, E1, E2, E4, and E9. It connects cleanup to the reported docutils failure. | Pass |
| C5 Leading-Empty-Line Compatibility | Matches I6 and E8. It does not preserve the buggy first-line-summary behavior. | Pass |
| C6 Public API Frame | Matches I7 and E10. No callsite or signature behavior is changed. | Pass |

## Adequacy Conclusion

The formal English claims cover the public intent without accepting the legacy
bug as expected behavior. No claim is supported only by current candidate
behavior. No SUSPECT public test was used to veto the issue intent.

The only trusted-base boundary is the standard-library claim from E6: this FVK
run models `inspect.cleandoc()` as the PEP 257 cleanup operation identified by
the public hint and the existing function comment.
