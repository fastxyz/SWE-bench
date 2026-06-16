# Iteration Guidance

Status: constructed, not machine-checked.

## V2 decision

Keep V1 source unchanged. The FVK audit found that V1 satisfies all feature-scope proof obligations:

- PO-001: parser accepts `--skip-checks`;
- PO-002: default behavior still runs system checks;
- PO-003: skipped path omits system checks;
- PO-004: migration checks remain enabled;
- PO-005: options propagate through reloader and non-reloader paths;
- PO-006: public in-repo subclass and programmatic call compatibility are preserved.

## Recommended public tests for a normal development pass

Do not edit tests in this benchmark. In a normal Django patch, useful tests would be:

- `runserver --skip-checks` is accepted by the parser.
- With `skip_checks=True`, `runserver.inner_run()` does not call `self.check()`.
- With `skip_checks=False`, `runserver.inner_run()` still calls `self.check(display_num_errors=True)`.
- `django.contrib.staticfiles` runserver accepts the inherited option.

## Machine-check follow-up

Run these only in an environment with K installed:

```sh
cd fvk
kompile mini-django-management.k --backend haskell
kast --backend haskell runserver-skip-checks-spec.k
kprove runserver-skip-checks-spec.k
```

Until `kprove` returns `#Top`, keep the proof labeled "constructed, not machine-checked" and do not remove any tests.
