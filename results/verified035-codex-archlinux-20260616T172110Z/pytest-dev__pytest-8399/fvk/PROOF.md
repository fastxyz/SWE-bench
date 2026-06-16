# Proof

Constructed, not machine-checked.

## What Is Proved

For the generated unittest/xunit setup fixture family, V1 restores the
underscore-prefixed fixture registration names required by public intent. Since
`pytest --fixtures` skips underscore-prefixed fixture argnames when
`verbose <= 0`, those generated fixtures are hidden from normal fixture listings
and remain available for verbose output and autouse execution.

## Formal Core

- Semantics: `fvk/mini-fixture-names.k`.
- Claims: `fvk/generated-fixture-privacy-spec.k`.
- Adequacy files: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`,
  `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
  `PUBLIC_COMPATIBILITY_AUDIT.md`.

The formal model abstracts away full Python execution and keeps only the
observable under audit:

1. generated fixture-name rendering;
2. classification of generated private names;
3. non-verbose/verbose fixture-listing filtering.

## Proof Sketch

1. By E2 and E5, each generated fixture registration in the affected family must
   have an underscore-prefixed `name=`.
2. In `repo/src/_pytest/unittest.py`, the only generated unittest fixture name
   template now renders `_unittest_{setup_name}_fixture_{obj.__qualname__}`.
   Therefore the generated unittest names for `setUpClass` and `setup_method`
   satisfy PO1.
3. In `repo/src/_pytest/python.py`, the generated xunit name templates now
   render `_xunit_setup_module_fixture_*`,
   `_xunit_setup_function_fixture_*`, `_xunit_setup_class_fixture_*`, and
   `_xunit_setup_method_fixture_*`. Therefore the xunit family satisfies PO2.
4. `_showfixtures_main` filters fixture defs with
   `if verbose <= 0 and argname[0] == "_": continue`. The explicit `name=`
   values become `fixturedef.argname`, so every name from steps 2 and 3 is
   skipped in non-verbose listing. This discharges PO3.
5. The V1 diff changes no fixture body, no `scope=`, no `autouse=True`, and no
   attachment attribute. This discharges PO4.
6. Static search found no remaining generated fixture name of the form
   `name=f"unittest_...` or `name=f"xunit_...`; all affected generated names
   now have `_` prefixes. This discharges PO5.
7. No public function/method signatures or hook signatures changed. This
   discharges PO6.
8. The adequacy audit maps every formal claim to public intent and marks each
   one pass. This discharges PO7.

## Machine-Check Commands

These commands are intentionally not executed in this benchmark run.

```sh
kompile fvk/mini-fixture-names.k --backend haskell
kast --backend haskell fvk/generated-fixture-privacy-spec.k
kprove fvk/generated-fixture-privacy-spec.k
```

Expected machine-check outcome after any necessary K syntax adjustment for the
local K version: `kprove` returns `#Top`.

## Test Recommendation

No test files were edited. Because the proof is constructed but not
machine-checked, no tests are recommended for deletion. Relevant tests should be
kept or added by project maintainers to cover:

- non-verbose `--fixtures` hides generated unittest fixtures;
- non-verbose `--fixtures` hides generated xunit module/function/class/method
  fixtures;
- verbose `--fixtures -v` can still show private generated fixtures.
