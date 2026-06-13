# Failing tests (FAIL_TO_PASS) and the test patch

Source: `eval/fvk.report.json` (authoritative for the FAIL_TO_PASS set) and the
test patch embedded in the goldcheck `eval.sh`
(`logs/run_evaluation/batch1-XC-MINI-PRO-AHP.goldcheck/gold/django__django-12325/eval.sh`).

## FAIL_TO_PASS set (2 tests)

```
test_clash_parent_link        (invalid_models_tests.test_relative_fields.ComplexClashTests)
test_onetoone_with_parent_model (invalid_models_tests.test_models.OtherModelTests)
```

- Gold patch result: both PASS (`test_output.txt` → `ok`, suite `OK (skipped=2)`,
  `Ran 205 tests`).
- V1 / FVK patch result: both FAIL (`fvk.report.json`: `FAIL_TO_PASS.success = []`,
  `failure = [both]`, `resolved: false`). Identical to `baseline.report.json` and
  `control.report.json` — **zero flips**.

## The decisive part of the test patch (from eval.sh)

The gold change **DELETES the old `test_missing_parent_link`** (which asserted that a
lone non-parent-link OTO to the parent *must* raise `ImproperlyConfigured`) and
**REPLACES** it with a test asserting the OPPOSITE — that a lone non-parent-link OTO
to the parent is now *valid* (no error):

```diff
-from django.core.exceptions import ImproperlyConfigured
 ...
-    def test_missing_parent_link(self):
-        msg = 'Add parent_link=True to invalid_models_tests.ParkingLot.parent.'
-        with self.assertRaisesMessage(ImproperlyConfigured, msg):
-            class Place(models.Model):
-                pass
-            class ParkingLot(Place):
-                parent = models.OneToOneField(Place, models.CASCADE)
+    def test_onetoone_with_parent_model(self):
+        class Place(models.Model):
+            pass
+
+        class ParkingLot(Place):
+            other_place = models.OneToOneField(Place, models.CASCADE, related_name='other_parking')
+
+        self.assertEqual(ParkingLot.check(), [])
+
+    def test_onetoone_with_explicit_parent_link_parent_model(self):
+        class Place(models.Model):
+            pass
+
+        class ParkingLot(Place):
+            place = models.OneToOneField(Place, models.CASCADE, parent_link=True, primary_key=True)
+            other_place = models.OneToOneField(Place, models.CASCADE, related_name='other_parking')
+
+        self.assertEqual(ParkingLot.check(), [])
```

`test_clash_parent_link` (new) asserts that when a child has a plain OTO to the
parent (`other_parent`) alongside the auto-created `parent_ptr`, the only errors are
the accessor/query-name clashes (`fields.E304/E305`) — i.e. NO `ImproperlyConfigured`.

## Why V1 fails these and the oracle passes

`test_onetoone_with_parent_model`: `ParkingLot` has a single **plain** OTO
(`other_place`, no `parent_link=True`) and no explicit parent link.

- **Oracle** (`isinstance(field, OneToOneField) and field.remote_field.parent_link`):
  `other_place` is *not* recorded in `parent_links` ⇒ Django auto-creates a
  `parent_ptr` parent link ⇒ no error. The oracle ALSO deletes the
  `if not field.remote_field.parent_link: raise ImproperlyConfigured(...)` guard in
  `options.py`. `check()` returns `[]`. PASS.
- **V1** (keep-last-wins fallback): the plain `other_place` IS recorded as the
  parent link (V1's `continue` only fires to protect an *existing* parent_link field;
  here none exists). `Options._prepare` still hits the un-removed
  `if not field.remote_field.parent_link: raise ImproperlyConfigured(...)` ⇒ raises
  `Add parent_link=True to …ParkingLot.other_place`. `check()` does NOT return `[]`.
  FAIL.

So the exact behavior V1 deliberately preserves (the lone-OTO `ImproperlyConfigured`
error, encoded as SPEC clause **I3** + the untouched `options.py` raise) is precisely
the behavior the gold patch removes. V1 retains the bug for the single-OTO case.
