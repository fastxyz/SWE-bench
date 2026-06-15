# Public Evidence Ledger

## E1: issue report, named group at end

- Source: `benchmark/PROBLEM.md`
- Evidence: "`replace_named_groups()` fails to replace the final named group if
  the urlpattern passed in is missing a trailing `/`."
- Obligation: `replace_named_groups()` must record and replace a balanced named
  group whose closing `)` is the final character of the pattern.
- Status: encoded by POB-N1 and K claim `REPLACE-NAMED-TRAILING`.

## E2: issue example, expected readable path

- Source: `benchmark/PROBLEM.md`
- Evidence: input
  `entries/(?P<pk>[^/.]+)/relationships/(?P<related_field>\w+)` should become
  `entries/<pk>/relationships/<related_field>`.
- Obligation: `simplify_regex()` must replace every named group in order,
  including the final one, while preserving intervening path text.
- Status: encoded by POB-S1 and K claim `SIMPLIFY-ISSUE-CASE`.

## E3: public hint, unnamed analogue

- Source: `benchmark/PROBLEM.md`
- Evidence: "Similar change should be made in `replace_unnamed_groups()`."
- Obligation: an unnamed group whose closing `)` is the final character must be
  recorded and replaced with `<var>`.
- Status: encoded by POB-U1 and K claim `REPLACE-UNNAMED-TRAILING`.

## E4: helper docstring, plural unnamed groups

- Source: `repo/django/contrib/admindocs/utils.py`
- Evidence: "`Find unnamed groups in pattern and replace them with '<var>'`."
- Obligation: all outermost unnamed groups in the verified pattern are replaced;
  the implementation must not duplicate text when more than one group exists.
- Status: encoded by POB-U2 and POB-U3. V1 failed this obligation; V2 changes
  the span filter and reconstruction cursor.

## E5: public tests, existing behavior to preserve

- Source: `repo/tests/admin_docs/test_views.py`
- Evidence: existing cases cover named groups followed by `/`, `$`, literal text,
  nested groups, one unnamed group, and cleanup of `^`, `$`, and `?`.
- Obligation: the source change must preserve those observable behaviors while
  extending coverage to groups at end of string.
- Status: encoded as frame conditions in POB-S1 and compatibility audit C1.

## E6: public callsite compatibility

- Source: `repo/django/contrib/admindocs/views.py`
- Evidence: `simplify_regex()` calls `replace_named_groups()` and then
  `replace_unnamed_groups()`.
- Obligation: keep helper signatures and return type unchanged; keep call order.
- Status: encoded by compatibility audit C1.
