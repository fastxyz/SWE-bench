# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 should not stand unchanged. Apply the V2 source edit already present in
`repo/src/_pytest/setuponly.py`.

Reason:

- F-002 shows V1 did not satisfy the full raw-param `saferepr` obligation from
  E-3/E-4.
- PO-003 requires all no-IDs raw params to use the bounded safe representation,
  not only non-string params.

## Required Code Shape

Keep these properties in future edits:

- Raw params with no explicit IDs are cached as
  `saferepr(request.param, maxsize=SETUP_SHOW_PARAM_MAXSIZE)`.
- `SETUP_SHOW_PARAM_MAXSIZE` remains below the default `saferepr` maxsize of 240;
  V2 uses 42.
- Explicit IDs pass through `_format_fixture_id`.
- `_format_fixture_id` preserves plain string labels and safe-represents
  non-string labels.
- `_show_fixture_action` writes the cached display string and does not call
  `saferepr` at write time, because by then raw params and explicit IDs have
  intentionally diverged.

## Suggested Tests for a Future Executable Environment

Do not add tests in this task; test files are fixed and hidden. Suggested future
coverage:

- `python -bb -m pytest --setup-show` with direct
  `@pytest.mark.parametrize("data", [b"Hello World"])` should complete setup
  display without `BytesWarning`.
- `--setup-show` with a fixture `params=[b"Hello World"]` should display a
  repr-style bytes value in setup and teardown.
- `--setup-show` with a long raw parameter should show a bounded representation.
- `--setup-show` with `ids=["spam"]` should keep `[spam]` as the explicit label.
- An ID function returning a bytes object should not raise `BytesWarning`.

## Machine-Check Follow-Up

Run these commands only in an environment with K installed:

```sh
kompile fvk/mini-pytest-setup-show.k --backend haskell
kast --backend haskell fvk/setup-show-spec.k -I fvk
kprove fvk/setup-show-spec.k -I fvk
```

Keep all tests until `kprove` returns `#Top` and normal pytest tests pass.

## Open Questions

None blocking. The only intentional behavior change is raw string parameters now
using repr-style safe output. That follows from the raw-param safe-repr intent in
F-002 and PO-003; explicit string IDs remain label-compatible per F-003 and
PO-004.
