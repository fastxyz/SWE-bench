# Intent Specification

Status: intent-only, before accepting candidate behavior as correct.

1. A user must not be able to crash request handling by submitting oversized `SelectDateWidget` date components.
2. The failing path is part of normal form validation, so malformed split date input should be transformed into a value that `DateField` can reject instead of raising an uncaught server exception.
3. The complete-triple path must account for user-controlled `year`, `month`, and `day` values.
4. Existing invalid complete triples are represented as pseudo-ISO strings with zero substitution for blank components.
5. Existing valid complete triples, all-empty triples, and missing-component fallback behavior should remain compatible.
6. The public method signature and caller protocol of `SelectDateWidget.value_from_datadict(data, files, name)` should remain unchanged.

