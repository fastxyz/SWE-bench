# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep V1 unchanged.

Rationale:

- Finding F1 is resolved by PO1: ordinary module specs now use `spec.name`.
- Finding F2 is resolved by PO1 and PO2: `foo.my__main__` remains an ordinary
  module name, while exact `__main__` and `.__main__` package entry points use
  `spec.parent`.
- Finding F3 is resolved by PO2: package entry-point behavior is preserved.
- Finding F4 is resolved by PO3 through PO7: the old fallback branches still run
  whenever no usable `-m` module name is available.
- PO8 confirms no public signature or return-shape compatibility issue.

## Suggested Future Tests

Do not add or edit tests in this benchmark. For maintainers, the following tests
would directly pin the issue behavior:

1. A fake `__main__.__spec__` with `name = "foo.bar.manage"` and
   `parent = "foo.bar"` should return
   `[sys.executable, "-m", "foo.bar.manage", "runserver"]`.
2. A fake top-level module spec with `name = "custom_module"` and empty parent
   should return `[sys.executable, "-m", "custom_module", "runserver"]`.
3. A fake module spec with `name = "foo.my__main__"` and `parent = "foo"` should
   return `[sys.executable, "-m", "foo.my__main__", "runserver"]`.
4. Existing package `__main__` tests should remain to pin
   `[sys.executable, "-m", "django", "runserver"]`.

## Machine-Checking Guidance

When a K environment is available, run:

```sh
cd fvk
kompile mini-python-argv.k --backend haskell
kast --backend haskell get-child-arguments-spec.k
kprove get-child-arguments-spec.k
```

Keep all tests until the proof returns `#Top`.

## Open Questions

No public-intent ambiguity blocks the code decision. The only residual question
is outside this benchmark: whether maintainers want the suggested future tests
as public regression coverage.
