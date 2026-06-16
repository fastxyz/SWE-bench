# Spec Audit

| Claim | Intent Match | Rationale |
|---|---|---|
| C1 | Pass | Matches D1 and E1-E3: final token is the parameter name, preceding tokens are the type. |
| C2 | Pass | Directly encodes the issue's concrete expected type/name boundary. |
| C3 | Pass | Preserves public test behavior for `:param str name:`. |
| C4 | Pass | Preserves documented `:param name:` behavior with no inline type. |
| C5 | Pass | Matches I4/E8: annotation merging must use the same final-token name rule. |
| C6 | Pass | Directly encodes the issue's concrete name for annotation merging. |

## Adequacy Notes

- The formal abstraction models whitespace-token splitting, not full docutils
  node construction.  This is adequate for the reported bug because the wrong
  observable is exactly the type/name boundary.
- The model does not claim type-expression whitespace normalization.  This is
  intentional per A1.
- No claim is derived solely from V1 output.  The rightmost-name rule is traced
  to the issue's expected `opc_meta` and the public `:param type name:` shape.
