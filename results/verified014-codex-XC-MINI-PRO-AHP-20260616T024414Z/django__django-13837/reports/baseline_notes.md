# Baseline Notes

## Root cause

`django.utils.autoreload.get_child_arguments()` detected `python -m django`
by importing `django.__main__` and comparing `sys.argv[0]` with
`django.__main__.__file__`. That made the autoreloader Django-specific: a
command started as `python -m other_package runserver` was restarted as a
script path instead of preserving `-m other_package`. It also depended on
module `__file__`, which is not guaranteed in every Python environment.

## Changed files

`repo/django/utils/autoreload.py`

Replaced the hard-coded `django.__main__.__file__` path comparison with
inspection of the top-level `__main__` module's `__spec__.parent`. When the
parent is set, Django now restarts the child process as
`python -m <package>` and passes through the original arguments after the
entry point. The existing warning option handling and Windows executable /
`-script.py` fallback paths are unchanged.

## Assumptions and alternatives considered

I assumed the issue is specifically about package entry points with a
`__main__` submodule, where Python sets `__main__.__spec__.parent` to the
package name. I also assumed directory and zipfile execution should keep the
existing path-based behavior because those cases have an empty spec parent.

I considered generalizing from `sys.argv[0]` paths such as `*/__main__.py`,
but rejected it because the issue points to Python's documented `__spec__`
signal and because path guessing would continue to rely on filesystem details.
I also rejected keeping the old Django-specific fallback because it would leave
the previous special case in place instead of making the detection package
agnostic.
