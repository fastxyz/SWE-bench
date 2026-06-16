# FVK Iteration Guidance

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged.

The FVK audit found that V1 discharges the required cache-winner obligations:
already-cached nested relations are preserved, missing relation caches still
receive the origin object, and both the one-to-one and ForeignKey reverse paths
named in the issue are covered.

## Code Guidance

Do not add a broader merge of partially-loaded model instances. That alternative
is not required by the intent ledger and would increase ORM state-merging risk.

Do not raise an exception for this nested prefetch shape. The intent describes a
well-defined successful behavior: the inner prefetch result should remain
usable.

Do not move the fix into unrelated query construction or matching code. The
proof localizes the bug to descriptor-side cache seeding after related queryset
evaluation.

## Suggested Tests For A Human Follow-Up

No tests were added or run in this task. If tests are added outside this
benchmark constraint, add integration tests for:

- reverse one-to-one: outer `User.objects.only("email")`, nested
  `Profile.user` queryset with `User.objects.only("kind")`, and zero extra
  queries for `user.profile.user.kind`;
- reverse many-to-one ForeignKey: the same assertion through
  `user.profile_set.all()[0].user.kind`;
- missing nested cache: normal prefetch still makes the child point back to the
  origin object without extra queries.

## Machine Verification Guidance

The K artifacts are constructed only. A future run with K installed should use:

```sh
cd fvk
kompile mini-prefetch-cache.k --backend haskell
kast --backend haskell prefetch-cache-spec.k
kprove prefetch-cache-spec.k
```

Keep all tests until a real machine check returns `#Top` and Django integration
tests pass in a real environment.
