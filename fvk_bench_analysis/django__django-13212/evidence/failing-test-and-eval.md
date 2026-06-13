# Failing test + eval evidence — django__django-13212

## A. The authoritative eval report (results/.../eval/fvk.report.json)
`resolved: false`. FAIL_TO_PASS reported as 3 success / 2 failure:
- success: char_field, integer_field, null_character
- **failure (per report): decimal_field, file_field**
- PASS_TO_PASS 2/2.

## B. *** INCIDENT: the report JSON over-counts the failure ***
The stored fvk-arm test run
(`logs/run_evaluation/batch1-XC-MINI-PRO-AHP.fvk/.../django__django-13212/test_output.txt`)
ends with:

    test_value_placeholder_with_char_field ... ok
    test_value_placeholder_with_decimal_field ... test_value_placeholder_with_file_field ... ok   <-- line 496: two tests' output concatenated
    test_value_placeholder_with_integer_field ... ok
    test_value_placeholder_with_null_character ... ok
    ======================================================================
    FAIL: test_value_placeholder_with_decimal_field (...) (value='NaN')
    ----------------------------------------------------------------------
      File ".../test_validators.py", line 157, in test_value_placeholder_with_decimal_field
        self.assertEqual(form.errors, {'field': [value]})
    AssertionError: {'field': ['%(value)s']} != {'field': ['NaN']}
    ----------------------------------------------------------------------
    Ran 7 tests in 0.062s
    FAILED (failures=1)

=> The fvk arm had **exactly ONE real failure**: the `decimal_field` test at the
`value='NaN'` sub-case. **`test_value_placeholder_with_file_field ... ok` — file_field PASSED.**
The report.json marks file_field as failed only because Django's subtest output put
decimal_field's (status-less, because a subTest failed) line and file_field's line on the
SAME physical line (line 496); the SWE-bench log parser keys on `<name> ... ok` and
mis-assigns file_field. The pytest-style summary `FAILED (failures=1)` is unambiguous.

## C. Contrast with the BASELINE arm (proves fvk really improved)
baseline `test_output.txt` ends with `FAILED (failures=1, errors=4)`:
- decimal_field: KeyError ERRORs on '123' / '0.12' / '12' (baseline never added value to
  DecimalValidator) + the NaN AssertionError.
- file_field: ERROR at line 168 (baseline never touched FileExtensionValidator -> KeyError).
So baseline genuinely failed BOTH decimal and file. fvk fixed file entirely and fixed the
3 decimal max_* sub-cases, leaving only the NaN sub-case. **At the test level fvk strictly
improved over baseline; the report scores them identically (resolved:false, F2P 3/5).**

## D. The single remaining failure, mechanically
`test_value_placeholder_with_decimal_field`, sub-case `("NaN","invalid")`
(tests/forms_tests/tests/test_validators.py:146-165):

    field = forms.DecimalField(max_digits=2, decimal_places=1,
                               error_messages={code: "%(value)s"})
    form = MyForm({"field": "NaN"});  assertEqual(form.errors, {"field": ["NaN"]})

Form clean chain (django/forms/fields.py): `to_python -> validate -> run_validators`.
- `DecimalField.to_python` parses `Decimal('NaN')` fine (NaN is a valid Decimal).
- `DecimalField.validate` (fields.py:353-358, UNTOUCHED by V1 and by fvk):
      def validate(self, value):
          super().validate(value)
          if value in self.empty_values: return
          if not value.is_finite():
              raise ValidationError(self.error_messages['invalid'], code='invalid')   # NO params
  `Decimal('NaN').is_finite()` is False -> raises HERE, *before* run_validators.
- Because this raise carries no params, `ValidationError.__iter__` skips `message %= params`,
  so the field's custom message renders verbatim as the literal `'%(value)s'`.
=> `{'field': ['%(value)s']}`, exactly the AssertionError. The (fvk-fixed) DecimalValidator
   is never consulted for NaN.

## E. The gold fix for this remaining case
Gold (evidence/oracle.patch.diff) does TWO things:
1. threads `params={'value': value}` through all core/validators.py raises, AND adds
   `code='invalid'` to the DecimalValidator NaN branch; and
2. **DELETES `DecimalField.validate()`** in django/forms/fields.py (lines 350-356 of the
   diff), so non-finite Decimals fall through to the (now value-bearing) DecimalValidator
   inside run_validators, where the custom message + `%(value)s` render.
Neither V1 nor fvk touched django/forms/fields.py at all -> NaN never escaped the override.
