# Spec Adequacy Audit

Status: constructed, not machine-checked.

| Formal English entry | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `preSqlSetup` stores primary IDs and model-keyed related parent-link IDs from a pre-update snapshot. | Intent obligations 1, 2, 3, 4. | Pass | Matches public hint and issue root cause. |
| `getRelatedUpdates` filters model `M` with `RIDS[M]`. | Intent obligation 2; ledger E6. | Pass | This is the explicit public hint and fixes the reported wrong-table-row update. |
| Bug discriminator maps `OtherBase` to `[3, 4]` when child/base keys are `[1, 2]`. | Problem example and ledger E2. | Pass | The exact numeric `[3, 4]` is an illustrative symbolic variant of the issue's distinct parent-link IDs; the property is inequality from child PKs when links differ. |
| Primary update remains filtered by `PKIDS`. | Intent obligation 3. | Pass | Preserves existing main-table update restriction. |
| Full SQL/database behavior is not modeled. | Default-domain assumptions. | Pass with caveat | This is a proof boundary, not a code finding, because the issue is about planning the wrong `pk__in` identifiers. |

No formal claim is derived solely from V1 behavior. Each required postcondition is
anchored to `benchmark/PROBLEM.md` or to the public hint included there.
