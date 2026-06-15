# Public Compatibility Audit

Changed symbol: `django.core.management.call_command()`.

Compatibility result: pass.

V1 does not change:

- the public function signature;
- command discovery or command loading;
- parser construction;
- `command.execute(*args, **defaults)` call shape;
- return shape;
- test files.

The only public behavior change is that kwargs satisfying a required mutually
exclusive group are made visible to argparse during the existing validation
pass. That change is the public issue's required behavior.
