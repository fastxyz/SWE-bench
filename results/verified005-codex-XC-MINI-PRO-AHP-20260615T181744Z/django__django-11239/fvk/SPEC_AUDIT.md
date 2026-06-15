# Spec Audit

## Adequacy gate

Status: pass, constructed not machine-checked.

| Formal claim | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `DBSHELL-SSL-ENV` | E1, E2, E3 | pass | Exactly covers the four SSL settings shown in the issue. |
| `DBSHELL-ARGS-FRAME` | E5 | pass | Preserves visible public dbshell argument behavior. |
| `DBSHELL-SIGINT-FRAME` | E5 / implementation contract | pass | V1 does not modify this behavior. |
| `DBSHELL-COMPATIBILITY` | E4, E5 | pass | No public signature or call shape changes. |

## Ambiguities checked

- Broader libpq option forwarding is under-specified by the issue. The issue names the mutual TLS
  SSL group and gives the four options formalized here. Arbitrary option forwarding is not needed
  to justify the V1 fix.
- Empty-string SSL values are not part of the issue example. The spec follows existing password
  handling style and only updates environment variables for truthy values.

## Conclusion

The formal English paraphrase is neither weaker nor stronger than the public issue intent for the
reported bug. The proof can justify leaving V1 unchanged.
