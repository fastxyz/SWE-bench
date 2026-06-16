# Findings

Constructed, not machine-checked.

## F1: Original Code Bug, Resolved By V1

- Classification: code bug.
- Input: a unittest class `Tests` with `setUpClass` and one test method.
- Pre-fix observed behavior: `pytest --fixtures` could list
  `unittest_setUpClass_fixture_Tests` as a normal non-private fixture with no
  docstring.
- Expected behavior: the generated fixture name starts with `_` and is hidden
  from non-verbose fixture listing.
- V1 result by static audit: `_unittest_setUpClass_fixture_Tests`.
- Related obligations: PO1, PO3.
- Status: resolved by V1.

## F2: Xunit Generated Fixture Family, Resolved By V1

- Classification: code bug across a related generated-name family.
- Input: xunit setup hooks such as `setup_class`, plus the sibling generated
  module/function/method setup hooks.
- Pre-fix observed behavior: generated names used public-looking
  `xunit_setup_*_fixture_*` templates.
- Expected behavior: every generated xunit setup fixture name starts with `_`.
- V1 result by static audit: all four xunit generated templates now start with
  `_xunit_`.
- Related obligations: PO2, PO5.
- Status: resolved by V1.

## F3: Behavior Preservation, Confirmed

- Classification: frame-condition audit.
- Input: any generated setup fixture that existed before V1.
- Observed V1 behavior by source diff: only `name=` string expressions changed.
- Expected behavior: setup/teardown execution semantics are unchanged; only
  fixture-listing privacy changes.
- Related obligations: PO4, PO6.
- Status: no additional source edit indicated.

## F4: Machine Check Not Run

- Classification: proof honesty caveat, not a code bug.
- Input: the FVK K claims in `generated-fixture-privacy-spec.k`.
- Observed: no `kompile`, `kast`, or `kprove` command was executed because the
  task forbids running K tooling.
- Expected next step outside this benchmark: run the commands listed in
  `PROOF.md` and expect `kprove` to return `#Top`.
- Related obligations: PO7.
- Status: constructed proof only; source decision still supported by the static
  intent and code audit.
