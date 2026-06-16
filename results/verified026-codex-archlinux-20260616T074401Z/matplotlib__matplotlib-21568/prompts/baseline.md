<!-- SECTION: header -->
# Task: fix a real GitHub issue in matplotlib/matplotlib

You are working in a benchmark workspace. The repository `matplotlib/matplotlib` is checked out at
commit `f0632c0fc7339f68e992ed63ae4cfac76cd41aad` in the `repo/` directory. A real GitHub issue from this
repository is described in `benchmark/PROBLEM.md`.

<!-- SECTION: allowed -->
## Allowed inputs
- `benchmark/PROBLEM.md` — the issue to fix (includes any public hints).
- `benchmark/instance.json` — public metadata about this task.
- Source code under `repo/`.

<!-- SECTION: forbidden -->
## Forbidden
- Internet access, external benchmark data, knowledge of the original upstream fix,
  hidden tests, evaluator scripts, or any files outside this working directory.
- Do not run tests or any code: this session has no execution environment. There are
  intentionally no test results available; do not infer or ask for them.
- Do not modify any test files: the project's test suite is fixed and hidden. Your
  fix must change non-test source code only.

<!-- SECTION: tasks -->
## Task
1. Read `benchmark/PROBLEM.md` carefully.
2. Explore the code under `repo/` to locate the root cause of the issue.
3. Implement the fix by directly editing the source files under `repo/`. Multi-file
   edits are allowed. Keep the change minimal and targeted: fix the described issue
   without unrelated refactoring.
4. Write `reports/baseline_notes.md` covering: the root cause; each file you changed
   and why; the assumptions you made and any alternative interpretations you
   considered and rejected.

<!-- SECTION: finish -->
## Finishing
Finish only after the code fix and `reports/baseline_notes.md` are both complete.
Your final message must be a one-paragraph summary of the fix.
