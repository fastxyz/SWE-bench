# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code defect within
the public issue's domain.

## Trace to Findings and Obligations

F1 and O1 show that the reported case,
`python -m pkg_other_than_django runserver`, is now represented by a
non-empty `__main__.__spec__.parent` and returns
`[sys.executable, "-m", package, ...]` with warning options preserved. This is
the core issue behavior, so no additional code edit is needed.

F2 and O4 show that the package-detection branch no longer imports
`django.__main__` and no longer compares against `django.__main__.__file__`.
That discharges the issue's `__file__` concern without needing a fallback path
heuristic.

F3, O2, and O3 show that empty or missing package parent values still fall
through to the existing script and Windows entrypoint fallback logic. This
preserves the directory/zip boundary described in the issue and keeps the
existing non-package behavior.

F4 explains why I did not restore the old path comparison to satisfy the
legacy public test shape that patches only `sys.argv[0]` to
`django.__main__.__file__`. That test mechanism conflicts with the issue's
requested `__main__.__spec__.parent` algorithm, so it is suspect evidence for
the mechanism even though real `python -m django` remains covered by O1.

F5 records an adjacent behavior, `python -m package.module`, as outside the
stated package-`__main__` issue. Because the public issue quotes the parent
algorithm directly and focuses on packages with their own `__main__`
submodule, I did not add a stricter `__spec__.name` condition in this repair.

O5 and O6 cover compatibility: warning options remain ordered as before, and
`restart_with_reloader()` still calls `get_child_arguments()` without any
signature or return-shape change.

## Artifact Summary

The FVK artifacts are under `fvk/`. The required summary files are
`SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and
`ITERATION_GUIDANCE.md`. Supporting methodology artifacts include the intent
and compatibility audits plus `mini-autoreload.k` and
`get-child-arguments-spec.k`.

The proof is constructed, not machine-checked. I did not run tests, Python, or
K tooling, in accordance with the task constraints.
