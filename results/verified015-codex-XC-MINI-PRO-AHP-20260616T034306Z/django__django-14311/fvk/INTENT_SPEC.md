# Intent Spec

This file records public intent before accepting the V1 implementation as
correct.

1. `python -m custom_module runserver` must autoreload by restarting with
   `python -m custom_module runserver`.
2. `python -m foo.bar.baz runserver`, where `baz.py` is an ordinary module file,
   must restart with `-m foo.bar.baz`, not `-m foo.bar`.
3. Package entry points whose executed module is exact `__main__` or ends with
   `.__main__` must restart with the package parent, preserving existing
   `python -m django` behavior.
4. A module name such as `foo.my__main__` is not a package `__main__` entry point
   and must remain the full restart module name.
5. Warning-option reconstruction and non-`-m` script fallbacks must be preserved:
   direct script path, Windows `.exe`, Windows `-script.py`, and missing-script
   error behavior.
6. `get_child_arguments()` must remain a zero-argument helper returning a command
   list or raising the existing missing-script RuntimeError.
