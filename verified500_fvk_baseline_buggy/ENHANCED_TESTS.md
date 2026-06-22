# Enhanced tests: turning FVK's catches into tests the hidden suite was missing

For the 3 flagship cases we wrote a **new regression test** that encodes the bug FVK caught, then ran it through the **official SWE-bench Docker harness** against both solutions. Every test **fails on the baseline** (RED — it catches the bug the hidden suite missed) and **passes on FVK** (GREEN).

These tests are exactly the "enhancement" the hidden suite needed: the existing graded tests passed *both* solutions, so they were blind to these bugs. Ours are not.

## Results (verified through `swebench.harness.run_evaluation`)

| New test | Baseline | FVK | Official human fix (gold) |
|---|:--:|:--:|:--:|
| `xarray/tests/test_fvk_regression.py::test_to_unstacked_dataset_preserves_length1_dim` | 🔴 FAIL | 🟢 PASS | 🔴 FAIL |
| `sklearn/ensemble/tests/test_fvk_regression.py::test_isolation_forest_positional_arg_compat` | 🔴 FAIL | 🟢 PASS | 🟢 (==FVK) |
| `tests/test_fvk_regression.py::test_unparse_one_element_tuple_subscript` | 🔴 FAIL | 🟢 PASS | 🔴 FAIL |

> **Two of the three new tests also fail on the official human fix** (xarray, Sphinx) — i.e. they would catch real, still-latent bugs in the upstream projects' own merged patches, not just the AI baseline. Only FVK passes all three.

Each result is backed by the harness's own `report.json`, copied into the per-instance `enhanced_tests/_proof/` folders. Example (xarray baseline): `FAIL_TO_PASS.failure = [test_to_unstacked_dataset_preserves_length1_dim]`; (xarray FVK): `FAIL_TO_PASS.success = [...]`, `resolved=true`.

## The tests

### 1. xarray-4094 — data must survive a round-trip
[`pydata__xarray-4094/enhanced_tests/test_fvk_regression.py`](pydata__xarray-4094/enhanced_tests/test_fvk_regression.py)
```python
arr = xr.DataArray(np.arange(1), coords=[("x", [0])])   # a length-1 'x' dimension
ds  = xr.Dataset({"a": arr, "b": arr})
unstacked = ds.to_stacked_array("y", sample_dims=["x"]).to_unstacked_dataset("y")
assert unstacked["a"].dims == ("x",)          # baseline & gold: dim destroyed -> ()  → FAIL
assert unstacked.identical(ds)                # FVK: lossless                          → PASS
```

### 2. scikit-learn-13496 — positional callers must not silently break
[`scikit-learn__scikit-learn-13496/enhanced_tests/test_fvk_regression.py`](scikit-learn__scikit-learn-13496/enhanced_tests/test_fvk_regression.py)
```python
clf = IsolationForest(100, "auto", "legacy", 1., False, 3, "new", 0, 1)   # positional, original public API
assert clf.n_jobs == 3 and clf.behaviour == "new" and clf.verbose == 1 and clf.warm_start is False
# baseline binds n_jobs="new", warm_start=3, ...  → AssertionError ('new' == 3) → FAIL ; FVK → PASS
```

### 3. sphinx-9367 — a one-element tuple subscript must keep its comma
[`sphinx-doc__sphinx-9367/enhanced_tests/test_fvk_regression.py`](sphinx-doc__sphinx-9367/enhanced_tests/test_fvk_regression.py)
```python
assert ast.unparse(ast.parse("obj[1,]").body[0].value, "obj[1,]") == "obj[1,]"
# baseline & gold render "obj[1]" (a different operation) → FAIL ; FVK → PASS
```

## How to reproduce (any of them)

The harness applies the solution patch, then applies our new test as a `test_patch`, then runs it — inside the exact Docker image that graded the benchmark (pulled from Docker Hub). Per instance we built a one-row dataset overriding `test_patch` (a new-file diff, so `get_test_directives` runs it) and `FAIL_TO_PASS` (our test's node id), and a prediction per arm (`model_patch` = `_materials/baseline.patch` or `_materials/fvk.patch`), then:

```bash
python -m swebench.harness.run_evaluation \
  --dataset_name /tmp/ds_<instance>.json \
  --predictions_path /tmp/pred_<instance>_<arm>.json \
  --run_id fvkt_<instance>_<arm> --instance_ids <instance> --cache_level env
# report: logs/run_evaluation/fvkt_<instance>_<arm>/<arm>/<instance>/report.json
```

Proof reports for each arm are saved under each instance's `enhanced_tests/_proof/`.
