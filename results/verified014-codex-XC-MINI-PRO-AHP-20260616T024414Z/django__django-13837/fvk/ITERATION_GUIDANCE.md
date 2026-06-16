# Iteration Guidance

Status: guidance derived from `FINDINGS.md` and `PROOF_OBLIGATIONS.md`.

## Code Decision

Keep V1 unchanged.

Reason: F1 and F2 show that V1 directly fixes the reported package-autoreload
bug and removes the `__file__` dependency. O1 and O4 are discharged by the
branch proof and source inspection. F3 shows the empty-parent boundary is
handled by the existing falsy branch condition.

## Rejected Changes

Do not reintroduce a `django.__main__.__file__` fallback.

Reason: F4 marks the path-only public test mechanism as suspect relative to
the issue's explicit `__spec__.parent` algorithm. Reintroducing that fallback
would make O4 weaker and preserve the mechanism the issue identifies as the
problem.

Do not add a path heuristic for `*/__main__.py`.

Reason: it would continue relying on filesystem shape rather than the public
spec-parent signal. It could also change explicit script execution into `-m`
execution without public intent evidence.

Do not add a `__spec__.name`-based restriction in this issue.

Reason: F5 identifies non-package `python -m package.module` as adjacent but
outside the stated package `__main__` issue. Adding that condition could make
the implementation stricter than the public algorithm quoted in the issue.

## Suggested Future Work

If maintainers want broader support for arbitrary `python -m module` entry
points, collect a separate public requirement and specify how
`__main__.__spec__.name`, `__main__.__spec__.parent`, and package
`__main__` execution should interact.

If the public tests are revised, update the `python -m django` test to model
`__main__.__spec__.parent == "django"` instead of only patching
`sys.argv[0]`.
