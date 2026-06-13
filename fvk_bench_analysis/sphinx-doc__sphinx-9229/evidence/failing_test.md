# Failing FAIL_TO_PASS test — `sphinx-doc__sphinx-9229`

Authoritative result: `results/batch4-XC-MINI-PRO-AHP-260613182909/sphinx-doc__sphinx-9229/eval/fvk.report.json`
→ `"resolved": false`; FAIL_TO_PASS failure list contains exactly one test.

```json
"FAIL_TO_PASS": {
  "success": [],
  "failure": [
    "tests/test_ext_autodoc_autoclass.py::test_class_alias_having_doccomment"
  ]
},
```
(All 13 PASS_TO_PASS — including `test_class_alias`, the bare-alias case — pass.)

## Gold test fixture + test (from the .fvk run's `eval.sh`)

Fixture added to `tests/roots/test-ext-autodoc/target/classes.py`:
```python
Alias = Foo

#: docstring
OtherAlias = Bar          # Bar is in the SAME module target.classes
```

Test added to `tests/test_ext_autodoc_autoclass.py`:
```python
def test_class_alias_having_doccomment(app):
    actual = do_autodoc(app, 'class', 'target.classes.OtherAlias')
    assert list(actual) == [
        '',
        '.. py:attribute:: OtherAlias',
        '   :module: target.classes',
        '',
        '   docstring',
        '',
    ]
```
The test asserts the alias renders as a `py:attribute` whose body is ONLY the
user comment `docstring` — NOT `alias of ...`.

## Actual failure under the fvk/V1 patch

`logs/run_evaluation/batch4-XC-MINI-PRO-AHP-260613182909.fvk/.../sphinx-doc__sphinx-9229/test_output.txt:480-499`
```
______________________ test_class_alias_having_doccomment ______________________
    def test_class_alias_having_doccomment(app):
        actual = do_autodoc(app, 'class', 'target.classes.OtherAlias')
>       assert list(actual) == [ '', '.. py:attribute:: OtherAlias',
                                 '   :module: target.classes', '', '   docstring', '' ]
E       AssertionError: assert ['', '.. py:a...ing', '', ...] == ['', '.. py:a...ocstring', '']
E         Left contains one more item: '   alias of :class:`target.classes.Bar`'
tests/test_ext_autodoc_autoclass.py:334: AssertionError
=================== 1 failed, 13 passed, 7 warnings in 0.73s ===================
```

**The defect is exact and single-line:** the V1/fvk output contains BOTH
`docstring` AND the extra `alias of :class:`target.classes.Bar`` line. The header
`.. py:attribute:: OtherAlias` is already correct. The surplus line comes solely
from `ClassDocumenter.add_content`'s unconditional `more_content = "alias of ..."`
injection, which the V1/fvk patch never touched.
