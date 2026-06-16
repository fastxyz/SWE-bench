# Public Evidence Ledger

Status: public evidence only; candidate behavior is used only as implementation
evidence.

## E1: Issue Title

Source: prompt / issue

Quote: "Allow autoreloading of `python -m pkg_other_than_django runserver`"

Semantic obligation: for package `P`, an invocation equivalent to
`python -m P runserver` must restart as `python -m P runserver`.

Status: encoded by O1 and claim `PACKAGE_MAIN`.

## E2: Existing Defect

Source: prompt / issue

Quote: "Currently it detects only when -m was passed specifically django"

Semantic obligation: the package name must not be hard-coded to `django`.

Status: encoded by O1/O4 and claim `PACKAGE_MAIN`.

## E3: Avoid `__file__`

Source: prompt / issue

Quote: "only in Python environments in which __file__ is set on modules, which
is not true of all Python environments"

Semantic obligation: the package `-m` branch must not import `django.__main__`
or compare against `django.__main__.__file__`.

Status: encoded by O4; discharged by the source inspection and `PACKAGE_MAIN`.

## E4: Documented Spec Parent Algorithm

Source: prompt / issue

Quote: "Python was started with -m pkg if and only if
__main__.__spec__.parent == \"pkg\"."

Semantic obligation: a non-empty `__main__.__spec__.parent` supplies the
package name for the reloader child command.

Status: encoded by O1 and claim `PACKAGE_MAIN`.

## E5: Directory / Zip Boundary

Source: prompt / issue

Quote: "`__main__.__spec__.parent` ... is the empty string when Python is
started with the name of a directory or zip file."

Semantic obligation: empty parent must not produce `-m ""`; it should use the
ordinary script/path handling.

Status: encoded by O2/O3 and claims `SCRIPT_EXISTS`, `EXE_FALLBACK`,
`SCRIPT_FALLBACK`, and `MISSING_SCRIPT`.

## E6: Warning Options and Fallbacks

Source: public tests under `repo/tests/utils_tests/test_autoreload.py`

Quote: `test_warnoptions`, `test_exe_fallback`, `test_entrypoint_fallback`,
and `test_raises_runtimeerror`.

Semantic obligation: warning options, existing script invocation, Windows
entrypoint fallbacks, and missing-script errors remain compatible when no
package parent exists.

Status: encoded by O2/O3.

## E7: Suspect Legacy Test Shape

Source: public tests under `repo/tests/utils_tests/test_autoreload.py`

Quote: `test_run_as_module` patches `sys.argv` to `django.__main__.__file__`
and expects `-m django`.

Semantic obligation: this is useful evidence that `python -m django` should
still restart as `-m django`, but the path-only simulation conflicts with the
issue's requested mechanism because it omits `__main__.__spec__.parent`.

Status: marked SUSPECT for mechanism only. It does not veto the public-intent
spec derived from E3/E4.
