# FVK Findings

Status: constructed findings from public intent, source inspection, and proof
obligations. No commands were executed.

## F1: V1 Fix Satisfies the Reported Package Autoreload Bug

Input / state: `sys.argv == [entrypoint, "runserver"]`,
`sys.warnoptions == []`, and `__main__.__spec__.parent == "pkg_other_than_django"`.

Observed in pre-fix code: the only `-m` branch compared `sys.argv[0]` with
`django.__main__.__file__`, so this package was not restarted as
`python -m pkg_other_than_django runserver`.

Expected by intent: `[sys.executable, "-m", "pkg_other_than_django", "runserver"]`.

Observed in V1 by source inspection: `package` is read from
`__main__.__spec__.parent`, so the non-empty package branch returns the expected
argument vector.

Classification: code bug fixed.

Related obligations: O1, O4.

Decision: no additional source change required.

## F2: V1 Removes the `__file__` Dependency From Package Detection

Input / state: a Python environment where the package entry module does not
provide useful `__file__`, but `__main__.__spec__.parent == "pkg"`.

Observed in pre-fix code: importing `django.__main__` and comparing
`django.__main__.__file__` was necessary for the only `-m` branch.

Expected by intent: package detection uses the documented `__spec__.parent`
metadata and works without module `__file__`.

Observed in V1 by source inspection: `get_child_arguments()` no longer imports
`django.__main__` and no longer reads `django.__main__.__file__`.

Classification: code bug fixed.

Related obligations: O1, O4.

Decision: no additional source change required.

## F3: Empty Parent Correctly Falls Through to Script/Fallback Logic

Input / state: directory or zipfile execution represented by empty/missing
package parent.

Observed risk: treating any non-`None` spec as `-m` would incorrectly produce
`-m ""`.

Expected by intent: the issue says directory/zip execution has empty parent,
so it must not be treated as package `-m`.

Observed in V1 by source inspection: the branch condition is `if package:`,
so empty parent is falsy and falls through to the existing path logic.

Classification: boundary case handled.

Related obligations: O2, O3.

Decision: no additional source change required.

## F4: Legacy Path-Only Test Mechanism Is Suspect, Not Controlling Intent

Input / state: a test patches only `sys.argv[0]` to `django.__main__.__file__`
without representing `__main__.__spec__.parent == "django"`.

Observed in V1 by source inspection: this path-only simulation is no longer
the detection mechanism.

Expected by issue intent: real `python -m django` remains supported because
its `__main__.__spec__.parent` is `"django"`; the path comparison itself is the
legacy mechanism the issue asks to replace.

Classification: suspect public-test mechanism / compatibility note.

Related obligations: O1, O4, O6.

Decision: do not restore the `django.__main__.__file__` fallback. Do not edit
tests; the benchmark test suite is fixed and hidden.

## F5: Non-Package `python -m package.module` Is Outside the Stated Issue Scope

Input / state: a program launched as `python -m package.module` rather than
through a package `__main__` submodule.

Observed in V1 by source inspection: the code follows the issue's parent-based
algorithm for non-empty parents.

Expected by public issue intent: the title and description focus on
`python -m pkg` utilities with their own `__main__` submodule.

Classification: underspecified adjacent behavior, not a blocking bug for this
issue.

Related obligations: O1 domain note.

Decision: do not add a `__spec__.name` check or path heuristic in this repair.
Such a broader behavior should be handled by a separate public requirement.

## Proof-Derived Findings From `/verify`

No proof obligation failed under the stated domain. The constructed proof is
not machine-checked, so no test deletion is recommended. The only audit warning
is F4: legacy public tests that encode path-based detection should be updated
by project maintainers if the public suite is revised, but production code
should follow the issue's spec-parent intent.
