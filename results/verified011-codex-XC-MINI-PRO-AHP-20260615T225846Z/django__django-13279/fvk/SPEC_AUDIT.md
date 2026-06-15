# Spec Adequacy Audit

Status: pass. The English meaning of the K claims matches the intent specification.

| Formal claim | Intent entry | Verdict | Rationale |
| --- | --- | --- | --- |
| Claim 1: SHA1 encodes legacy | Intent 1, 2; ledger E1-E3 | Pass | The claim states the exact branch requested by the issue. |
| Claim 2: SHA1 legacy round trip | Intent 1; ledger E1, E2 | Pass | The claim captures the rolling-upgrade compatibility requirement: data written in transition mode is decodable by older instances. |
| Claim 3: current decode accepts legacy | Intent 4; ledger E6 | Pass | Existing fallback behavior is part of the compatibility surface and is not weakened. |
| Claim 4: SHA256 default preserved | Intent 3; ledger E4, E5 | Pass | The claim preserves default Django 3.1 behavior outside the transition setting. |
| Claim 5: current decode accepts signed | Intent 4 | Pass | The claim preserves decoding of the new format. |
| Side conditions | Intent 5 | Pass | Serializer/secret/store-class consistency is a necessary public deployment precondition for shared session compatibility. |

## Ambiguities

None that block `V2 == V1`.

## Suspect Legacy Behavior

The pre-fix behavior "SHA1 setting writes a signing.dumps payload" is marked SUSPECT because it is the behavior described by the issue as insufficient. It is not used as an expected result.

