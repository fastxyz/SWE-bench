# FINDINGS.md — `get_child_arguments()` (V1 audit)

Plain-language findings, each as `input → observed vs expected`. Non-blocking; this
report never edits code. The headline is **one real limitation (F1)** that the issue's
own algorithm shares and that is **out of the ticket's domain**, plus several findings
that **confirm V1 is correct and an improvement** over the pre-fix code.

Legend for classification: `code-bug` · `missing-precondition` · `underspecified-intent`
· `needed-guard` (positive) · `out-of-domain` · `escalation`.

---

## F1 — `python -m PKG.MOD` where `MOD` is a *non-package* sub-module → wrong `-m` target
**Classification: underspecified-intent / out-of-domain (the issue's stated scope
excludes it). NOT recommended for a code change in this ticket — see below.**

- **input:** launched as `python -m mysite.runner runserver`, where
  `mysite/runner.py` is a *module* (not a package) that calls
  `execute_from_command_line()`. Then `__main__.__spec__.name == "mysite.runner"` and,
  because `runner` is not a package, `__main__.__spec__.parent == "mysite"`.
- **observed (V1):** branch **M** fires and returns
  `[exe, '-m', 'mysite', 'runserver']` → the child runs `python -m mysite`, i.e.
  `mysite/__main__.py` (a *different* entry point), or **fails** with
  `No module named mysite.__main__` if `mysite` has none.
- **expected:** `[exe, '-m', 'mysite.runner', 'runserver']` (re-run the *same* module).

**Why it is out of domain, not a bug to fix here.** The ticket *defines* the contract as
"started with `-m pkg` iff `__main__.__spec__.parent == 'pkg'`", and its motivating use
case is "a **package** with its own `__main__` sub-module overriding runserver." For a
**package** `-m PKG`, `__main__` is the spec of `PKG.__main__`, so `parent == "PKG"` and
V1 is exactly right (precondition **D3** in [`SPEC.md`](SPEC.md)). The failing case is
the *complement* of D3 — a directly-run non-package sub-module — which the ticket does
not ask to support. Characterization (CPython `ModuleSpec.parent`):

| launch `python -m X` | `__main__.__spec__.name` | `.parent` | V1 `-m` arg | verdict |
|---|---|---|---|---|
| `X = PKG` (package) | `PKG.__main__` | `PKG` | `PKG` | **correct** (issue case) |
| `X = PKG.SUB` (sub-package) | `PKG.SUB.__main__` | `PKG.SUB` | `PKG.SUB` | **correct** |
| `X = PKG.MOD` (sub-module) | `PKG.MOD` | `PKG` | `PKG` | **F1 — wrong** |
| `X = MOD` (top-level module) | `MOD` | `""` | (falls through) | benign — see F6 |

So V1 is faithful **exactly when the `-m` target is a package**, i.e. when
`spec.name.endswith('.__main__')`. The optional refinement that would also cover F1 is
recorded in [`ITERATION_GUIDANCE.md`](ITERATION_GUIDANCE.md) — and *rejected for this
ticket* because it diverges from the ticket-mandated `__spec__.parent` algorithm and adds
risk against tests built on that algorithm (see PO-D3 in
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md)).

---

## F2 — `__spec__` absent (e.g. Conda / embedded) is handled safely *(positive — needed-guard)*
- **input:** an environment where the `__main__` module has **no** `__spec__` attribute
  at all; server started as a plain script `manage.py runserver`.
- **observed (V1):** `getattr(__main__, '__spec__', None)` → `None`, so branch **M** is
  skipped and the launch is treated as a script (branch **S**) →
  `[exe, *Wf, manage.py, runserver]`. ✓
- **expected:** exactly that. **The `getattr(…, None)` default is a required guard**: a
  bare `__main__.__spec__` would `AttributeError` in such environments. Confirms a
  correctness-relevant detail of V1.

## F3 — directory / zipfile launch correctly excluded *(positive — needed-guard)*
- **input:** `python /srv/app.zip runserver` (or a directory). Per the ticket,
  `__main__.__spec__` is **not** `None` but `__main__.__spec__.parent == ""`.
- **observed (V1):** the second conjunct `and __main__.__spec__.parent` is `"" →` falsy,
  so branch **M** is skipped; `argv[0]` (the zip/dir) exists → branch **S** →
  `[exe, *Wf, /srv/app.zip, runserver]`, which re-runs the zip/dir. ✓
- **expected:** exactly that. The `and parent` truthiness test is the precise mechanism
  that separates "real `-m pkg`" from "directory/zipfile in `sys.path`". Confirms V1.

## F4 — `__file__` reliance removed; `-m django` still works *(positive)*
- **input (a):** `python -m django runserver`. `__main__.__spec__.parent == "django"` →
  branch **M** → `[exe, '-m', 'django', 'runserver']`. ✓ **backward compatible.**
- **input (b):** a frozen/zipapp environment where modules do **not** expose `__file__`.
  The pre-fix code computed `Path(django.__main__.__file__)` and could fail there (the
  defect the ticket calls out: detection "only ... in Python environments in which
  `__file__` is set"). V1 never reads `__file__`, so detection is environment-independent.
  ✓ This is the second half of the ticket, now satisfied.

## F5 — `sys.argv == []` would raise `IndexError` *(pre-existing, out of scope)*
- **input:** an embedding that leaves `sys.argv` empty.
- **observed:** `Path(sys.argv[0])` raises `IndexError`. Present in the pre-fix code too;
  not introduced or worsened by V1. **Domain assumption D1** documents `len(argv) ≥ 1`.
  Recommend leaving as-is (CPython always populates `argv[0]`); noted for completeness.

## F6 — top-level module `python -m singlemod runserver` re-runs as a script *(benign,
pre-existing class)*
- **input:** `python -m singlemod runserver`, `singlemod.py` a top-level module. Then
  `__main__.__spec__.parent == ""`.
- **observed (V1):** branch **M** skipped (empty parent) → branch **S** →
  `[exe, *Wf, /path/singlemod.py, runserver]`, re-running the *same file* as a script.
- **expected (ideal):** `-m singlemod`. The script re-run executes the same file and is a
  benign equivalence for a *top-level* module (it just loses the `-m`/`__package__`
  framing). Distinct from F1, which runs a **different** file. Same class as F1 but not
  harmful; out of domain.

---

## Spec-difficulty signal (benefit-2 meta-finding)
A **clean** precondition/postcondition contract *was* writable for the intended domain
(branches M/X/R/S, §1 of [`SPEC.md`](SPEC.md)); the guards visibly partition the input
space (PO-EXH). The *only* place the spec needed a careful domain restriction is **D3**,
and that restriction coincides exactly with the ticket's stated scope. Low spec
difficulty ⇒ corroborates that **V1 is sound on its domain** and that the residual F1/F6
behavior is an *intent* boundary, not a hidden implementation bug.

## Proof-derived findings from `/verify`
See [`PROOF.md`](PROOF.md) §5. Summary: every guard branch discharges by Case Analysis +
symbolic execution to its claimed `<out>`; **PO-EXH** (exhaustive, mutually-exclusive
guards) and **PO-WF** (the `-W` map) discharge with no open arithmetic. The single
*non-formal* obligation is **PO-D3** (the package-vs-module intent assumption behind F1),
which is an **[ESCALATION BOUNDARY]**: it cannot be decided without an OS/import model and
is therefore a *kept-test / intent-elicitation* item, not a proof gap in the code.
