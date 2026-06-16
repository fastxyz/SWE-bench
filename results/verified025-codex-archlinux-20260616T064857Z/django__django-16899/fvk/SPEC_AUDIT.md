# Spec Audit

Status: constructed, not machine-checked.

## Adequacy check

K-01 vs I-01, I-02, I-03, I-04: pass. The formal invalid-entry claim requires
both the indexed option label and the invalid field value in the `admin.E035`
message representation, matching the issue intent and neighboring check style.

K-02 vs I-01, I-02: pass. The formal caller claim keeps the indexed
`readonly_fields[index]` label and carries the same invalid field value into the
message.

K-03 through K-06 vs I-04: pass. The valid-entry branches remain no-error
branches.

S-01 vs I-01: pass. Non-negative indexes are a named default-domain assumption
from Python enumeration.

S-02 vs I-02, I-03: pass. The abstraction preserves the defect-relevant axis:
whether the invalid field value is present in the error message.

I-05 vs formal claims: pass with source-code audit. The K result uses
`admin.E035`; the unchanged source still passes `obj=obj.__class__`.

I-06 vs formal claims: pass after V2 docs update. The runtime behavior and
public checks reference now describe the same message shape.

I-07 vs formal claims: pass as SUSPECT evidence handling. Existing public tests
asserting the old message are not used as a postcondition because they conflict
with the issue.

## Result

The formal claims are adequate for the public issue intent. The proof can
justify leaving V1's code logic unchanged, while F-02 justifies a documentation
update.
