# FVK Findings

Status: constructed, not machine-checked.

## FVK-001: `replace` omitted commit `userData`

Classification: code bug, resolved by V1.

Evidence:

- Public issue: "`replace` method doesn't set `userData` with the new user data from `other`."
- Pre-V1 code: `rollbackSegmentInfos(other.asList()); lastGeneration = other.lastGeneration;`
  left `this.userData` unchanged.

Concrete input:

```text
this = si(segments=A, lastGeneration=1, userData={commit: latest}, generation=10, version=20, counter=30)
other = si(segments=B, lastGeneration=2, userData={commit: requested}, generation=2, version=5, counter=7)
```

Observed before V1:

```text
this.userData == {commit: latest}
```

Expected:

```text
this.userData == {commit: requested}
```

Resolution:

`repo/lucene/core/src/java/org/apache/lucene/index/SegmentInfos.java` now assigns
`userData = other.userData;` in `replace`, discharging proof obligation PO-3.

## FVK-002: Defensive copy is not required for the intended repair

Classification: rejected alternative, no code change.

Evidence:

- Public issue's candidate fix uses direct assignment.
- `DataInput.readMapOfStrings()` documents an immutable map result.
- Existing local conventions store commit user data references directly in `setUserData` and commit
  point classes.

Observed concern:

```text
replace could use new HashMap<>(other.userData)
```

Expected under public intent:

```text
replace must make this commit metadata equal to other's commit metadata; it need not introduce a
new copy policy.
```

Resolution:

V1 stands. Adding a defensive copy would be a broader behavior change than the issue requires and
is not needed to satisfy PO-3.

## FVK-003: Proof is constructed but not machine-checked

Classification: proof process caveat, not a code bug.

Evidence:

The benchmark forbids running K tooling. The commands in `SPEC.md` and `PROOF.md` are recorded for
later execution only.

Resolution:

No tests or verification tooling were run. Test deletion is not recommended.
