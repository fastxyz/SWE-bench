# Intent Spec

Status: intent-only requirements from public evidence. Current implementation behavior is not used as expected behavior unless independently supported.

## Required Behaviors

1. Django admin/form display for `JSONField` values containing non-ASCII Unicode text must show readable Unicode characters rather than JSON `\uXXXX` escape sequences.

2. The requirement applies to the family of JSON-serializable values containing non-ASCII text, including the issue's Chinese example and similar emoji/Japanese/non-ASCII text cases mentioned in the public issue.

3. Invalid submitted JSON must still be redisplayed as submitted and not be overquoted by JSON serialization.

4. Custom encoders configured on the form or model field must remain honored by the display serialization path.

5. The fix must be display-only. Database JSON preparation, validation, and backend storage behavior are frame conditions and should not change.

6. The existing form rendering/template escaping path must remain in place.

## Out of Scope

This FVK pass does not specify database acceptance of every Unicode scalar or backend encoding policy. The public issue explicitly separates the admin/form display problem from MySQL write/read behavior.

This FVK pass does not prove full Python `json.dumps()` correctness. It models only the `ensure_ascii` behavior needed to distinguish the reported display defect from the intended display behavior.
