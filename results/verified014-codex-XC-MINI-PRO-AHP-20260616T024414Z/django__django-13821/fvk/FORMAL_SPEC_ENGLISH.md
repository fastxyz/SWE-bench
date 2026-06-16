# Formal Spec in English

Status: constructed for FVK, not machine-checked.

## Claims

`reject-sqlite-below-390`

For any nonnegative SQLite version tuple `(major, minor, patch)` and any version
display string, if the tuple is lexicographically less than `(3, 9, 0)`, then
`check_sqlite_version()` raises `ImproperlyConfigured` with the message
`SQLite 3.9.0 or later is required (found <display>).`

`accept-sqlite-390-or-newer`

For any nonnegative SQLite version tuple `(major, minor, patch)` and any version
display string, if the tuple is not lexicographically less than `(3, 9, 0)`, then
`check_sqlite_version()` returns normally.

## Frame Conditions

The proof model abstracts only the support-floor behavior of
`check_sqlite_version()`. It does not change public signatures, database feature
probing, connection creation, schema editing, or JSON1 detection.

## No Loop or Recursion Obligations

The audited function has no loops or recursion. No circularity claim is needed.
