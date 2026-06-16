# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed public symbol

C-1. `django.core.management.base.OutputWrapper`

Change: V1 adds an explicit `flush(self)` method. It does not change constructor
arguments, `write()` arguments, `style_func`, `isatty()`, `BaseCommand.__init__()`, or
`BaseCommand.execute()`.

Compatibility verdict: pass.

Reasoning: `BaseCommand.__init__()` already wraps stdout/stderr at `base.py` lines
243-245, and `execute()` already wraps option-provided streams at lines 386-389.
Adding `flush()` makes an existing callable operation work; it does not require callers
or subclasses to pass new arguments or accept new keyword parameters.

## Public call sites and consumers

C-2. `migrate` progress callback

Public call site: `migrate.py` lines 278-301 calls `self.stdout.flush()` after
partial-line writes.

Compatibility verdict: pass.

Reasoning: V1 satisfies the existing call shape. No migrate source change is required.

C-3. Custom stdout/stderr streams

Public evidence: `tests/admin_scripts/tests.py` lines 1542-1572 use `StringIO` for
custom command streams and assert write output.

Compatibility verdict: pass.

Reasoning: V1 does not alter `write()`, stream replacement, or formatting. `StringIO`
has a `flush()` method, so delegated flushing is compatible with the intended stream
protocol. The `hasattr()` guard keeps objects with only a `write()` method from failing
solely because the wrapper now exposes `flush()`.

## Unhandled overrides or call sites

None found in the audited source slice. No subclass override signature or virtual
dispatch call was changed.
