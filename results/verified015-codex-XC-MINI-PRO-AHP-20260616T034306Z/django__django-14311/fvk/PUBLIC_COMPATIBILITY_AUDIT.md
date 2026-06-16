# Public Compatibility Audit

Status: pass.

## Changed symbol

`django.utils.autoreload.get_child_arguments`

Compatibility result:

- Signature remains `get_child_arguments()` with no parameters.
- Non-error return shape remains a command list suitable for `subprocess.run()`.
- Existing missing-script error type and message shape are preserved.

## Public callsites

| Callsite | Compatibility result |
| --- | --- |
| `django.utils.autoreload.restart_with_reloader()` | Calls `get_child_arguments()` without arguments; unchanged. |
| Public tests in `repo/tests/utils_tests/test_autoreload.py` | Test helper calls remain valid; no public test API or fixture shape changes are required. |

## Subclasses and overrides

No subclass or override surface exists for `get_child_arguments()`.

## Producer/consumer shape

The producer remains `get_child_arguments()` and the consumer remains
`subprocess.run(args, env=..., close_fds=False)`. V1 changes only the selected
module string inside the list for `python -m` ordinary module specs.
