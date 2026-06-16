# Spec Audit

Status: constructed, not machine-checked.

| Formal English item | Intent item | Result | Notes |
|---|---|---|---|
| Scalar `x` returns empty attrs. | Intent 1, 3; ledger E1, E5. | Pass | Scalar `x` is public input and has no attrs source. |
| Singleton reproducer does not index attrs position 1. | Intent 1; ledger E2. | Pass | Directly targets the reported `IndexError`. |
| Scalar `x` does not fall back to `y`. | Intent 2, 3; ledger E4. | Pass | `keep_attrs=True` means attrs of `x`, not "second xarray object". |
| X-source attrs are preserved by content. | Intent 2; ledger E4. | Pass | Public attrs equality is content-based; identity is not specified. |
| No x source in a merge returns empty attrs. | Intent 3; ledger E4, E6. | Pass | This covers coordinate/variable merge calls where `x` is not a contributor. |
| Non-`True` modes and call shape unchanged. | Intent 4, 5; ledger E7. | Pass | V1 changes only the custom `keep_attrs is True` callable. |

No formal-English item is weaker than the public intent. No public behavior is intentionally preserved from the legacy bug.
