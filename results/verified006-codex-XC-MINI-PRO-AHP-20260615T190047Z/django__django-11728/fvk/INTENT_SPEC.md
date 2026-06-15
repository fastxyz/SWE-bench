# Intent Spec

Status: constructed from public issue text, docstrings, public in-repo tests, and
the current source under audit. No hidden tests, evaluator data, or upstream fix
knowledge were used.

## Required behavior

1. `simplify_regex()` must turn URL regex fragments into readable URL patterns.
   Named groups become their angle-bracket names, unnamed groups become
   `<var>`, regex anchors are removed, and a leading slash is added when absent.

2. A named capture group must be replaced whether it is followed by `/`, `$`,
   literal text, or the end of the pattern. The issue example
   `entries/(?P<pk>[^/.]+)/relationships/(?P<related_field>\w+)` requires the
   final `related_field` group to become `<related_field>` without requiring a
   trailing slash.

3. The same end-of-pattern behavior applies to unnamed capture groups because
   the public hint explicitly says the analogous change should be made in
   `replace_unnamed_groups()`.

4. For unnamed groups, the helper's plural contract and examples require all
   outermost unnamed capture groups to be replaced, not only the first one. Text
   between groups must be preserved exactly once, and nested groups inside an
   outer unnamed group must not produce additional `<var>` replacements because
   the outer group replacement already consumes them.

5. The repair must preserve public compatibility: no function signatures,
   return types, imports, or call order in `simplify_regex()` may change.

## Domain assumptions

- The verified domain is finite string patterns whose capture-group parentheses
  are balanced according to the helper's existing rule: an unescaped `(` opens a
  group and an unescaped `)` closes it.
- The proof is partial correctness: if the helpers return on an in-domain
  pattern, their result satisfies the specified replacement behavior. Termination
  is argued informally by finite-string iteration, not machine-proved.
- Full Python `re` syntax is outside the mini-semantics. The model covers the
  span-finding and reconstruction behavior directly changed by this fix.
