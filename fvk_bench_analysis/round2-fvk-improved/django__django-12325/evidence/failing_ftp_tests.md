# Failing FAIL_TO_PASS tests — round-2 fvk (eval/fvk.report.json)

`resolved: false`. FAIL_TO_PASS.success = []; failure = both. PASS_TO_PASS all green
(no over-reach / no PTP breakage). FAIL_TO_FAIL and PASS_TO_FAIL empty.

```
FAIL_TO_PASS failures:
  test_clash_parent_link        (invalid_models_tests.test_relative_fields.ComplexClashTests)
  test_onetoone_with_parent_model (invalid_models_tests.test_models.OtherModelTests)
```

Baseline report is identical (same 2 failures, resolved:false) — and the two patch
files are byte-identical, so fvk neither helped nor hurt vs baseline. Zero flip.

## What the decisive test asserts (gold test patch; from round-1 evidence/failing_tests.md, reconstructed from goldcheck eval.sh)

The gold TEST patch **DELETES** the old `test_missing_parent_link` (which asserted a
lone non-parent-link OTO to the parent MUST raise `ImproperlyConfigured`) and
**REPLACES** it with the opposite assertion:

```diff
-from django.core.exceptions import ImproperlyConfigured
-    def test_missing_parent_link(self):
-        msg = 'Add parent_link=True to invalid_models_tests.ParkingLot.parent.'
-        with self.assertRaisesMessage(ImproperlyConfigured, msg):
-            class Place(models.Model): pass
-            class ParkingLot(Place):
-                parent = models.OneToOneField(Place, models.CASCADE)
+    def test_onetoone_with_parent_model(self):
+        class Place(models.Model): pass
+        class ParkingLot(Place):
+            other_place = models.OneToOneField(Place, models.CASCADE, related_name='other_parking')
+        self.assertEqual(ParkingLot.check(), [])          # <-- lone plain OTO is now VALID
+
+    def test_onetoone_with_explicit_parent_link_parent_model(self):
+        class Place(models.Model): pass
+        class ParkingLot(Place):
+            place = models.OneToOneField(Place, models.CASCADE, parent_link=True, primary_key=True)
+            other_place = models.OneToOneField(Place, models.CASCADE, related_name='other_parking')
+        self.assertEqual(ParkingLot.check(), [])
```

`test_clash_parent_link` (new): a child with a plain OTO to the parent alongside the
auto-created `parent_ptr` yields ONLY the accessor/query-name clashes (E304/E305) —
critically, **no** `ImproperlyConfigured`.

## Why V1 (=fvk patch) FAILS `test_onetoone_with_parent_model`

`ParkingLot` has a single PLAIN OTO (`other_place`, no `parent_link=True`).

- **Gold**: `other_place` is not `parent_link=True`, so HUNK 1 excludes it from
  `parent_links`. With no parent link recorded, Django auto-creates `place_ptr`.
  HUNK 2 has removed the `options.py` raise. `check()` == [] -> PASS.
- **V1/fvk**: V1 keeps the broad predicate; `other_place` IS recorded as the parent
  link (the `continue` guard only protects an *existing* parent_link field, and none
  exists here). `Options._prepare` reaches the UN-removed
  `if not field.remote_field.parent_link: raise ImproperlyConfigured('Add parent_link=True to ...other_place')`
  -> raises -> `check()` != [] -> FAIL.

The behavior V1 deliberately preserves (the lone-OTO ImproperlyConfigured error,
encoded as obligation O2 / intent I2) is exactly the behavior the gold patch removes.

## Failure class: PARTIAL (missing both gold hunks), driven by an INVERTED adequacy obligation
Not a wrong-location case: V1 is in the exact right file/method (base.py parent_links
loop) and even reads + reasons about the exact options.py raise. It is missing BOTH
gold hunks because the fvk audit certified the lone-OTO error as a MUST-hold
obligation (O2), inverting the required direction.
