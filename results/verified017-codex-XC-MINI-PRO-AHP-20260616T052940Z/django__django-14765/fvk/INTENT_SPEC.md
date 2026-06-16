# INTENT SPEC

Status: intent-only. Current implementation behavior is mentioned only as an
observed candidate to audit.

1. `ProjectState.__init__()` may assume `real_apps` is already a set whenever
   it is provided.
2. The constructor must assert that any non-`None` `real_apps` value is a set.
3. The constructor must stop converting non-set iterables into sets.
4. `real_apps=None` remains the sentinel for no real apps and should create an
   empty set.
5. The issue frames direct construction as internal or semi-internal, so
   rejecting external non-set iterable calls is acceptable for this change.
6. The change should be minimal and should not alter unrelated constructor
   fields.

