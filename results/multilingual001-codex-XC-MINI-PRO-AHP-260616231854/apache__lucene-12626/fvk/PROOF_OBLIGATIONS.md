# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Domain

Claim:

`replace` is specified for a non-null `other` `SegmentInfos` instance.

Provenance:

Package-private Java method, public issue snippet, and current callers all dereference `other`
without a null guard. The issue is about state transfer, not null handling.

Status:

Discharged as a precondition/default-domain assumption.

## PO-2: Segment List Replacement

Claim:

After `replace(other)`, this instance's segment list equals `other.asList()`.

Provenance:

Existing implementation calls `rollbackSegmentInfos(other.asList())`; this behavior is part of the
method's replacement contract and is not challenged by the issue.

Status:

Discharged by the call to `rollbackSegmentInfos`.

## PO-3: Commit User Data Replacement

Claim:

After `replace(other)`, this instance's `userData` equals `other.userData`.

Provenance:

Public issue E1 and E2 in `SPEC.md`.

Status:

Discharged by the V1 assignment:

```java
userData = other.userData;
```

The pre-V1 implementation fails this obligation when `this.userData != other.userData`.

## PO-4: Last Generation Replacement

Claim:

After `replace(other)`, this instance's `lastGeneration` equals `other.lastGeneration`.

Provenance:

Existing method body and issue snippet both include `lastGeneration = other.lastGeneration`.

Status:

Discharged by the existing assignment.

## PO-5: Write-Once Metadata Frame

Claim:

After `replace(other)`, this instance's `generation`, `version`, and `counter` remain the receiver's
pre-state values.

Provenance:

The method comment says `replace` keeps generation, version, and counter so future commits remain
write once.

Status:

Discharged because V1 adds only `userData = other.userData` and does not assign these fields.

## PO-6: Public Compatibility

Claim:

The fix must not change public APIs, method signatures, serialization order, or tests.

Provenance:

Benchmark constraints and Lucene compatibility risk.

Status:

Discharged. The only source edit is a field assignment inside a package-private method.

## PO-7: Formal Adequacy

Claim:

The K claim must distinguish the reported failing behavior from the expected behavior.

Provenance:

FVK adequacy gate and issue E1.

Status:

Discharged. In `fvk/segmentinfos-replace-spec.k`, if `SELF_USER != OTHER_USER`, the post-state
contains `OTHER_USER`. The pre-V1 transition would leave `SELF_USER` and therefore fail the claim.
