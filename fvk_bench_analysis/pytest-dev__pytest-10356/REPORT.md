# Formally Verified AI Code — Case Study: `pytest-dev/pytest#10356`

*How formal methods made a frontier code-generation model fix a bug it had confidently shipped — and why that is the product, not a demo.*

*Provenance: run `fvk-improved-4cases-XC-MINI-PRO-AHP` (model `claude-opus-4-8`). The "baseline" and "FVK" runs below are the **same** code-generation model on the **same** task; the only difference is whether it worked under FVK's formal-methods discipline. Baseline → unresolved; FVK → resolved.*

---

## 1. The stakes

AI now writes most of the world's new code. The danger was never code that fails loudly — you catch that. The danger is code that **looks right, passes the obvious tests, and is wrong in exactly the place that matters.** That is the output that ends up in your auth layer, your trading engine, your control plane — and it is the output that no one today can certify. Every organization shipping AI code is exposed to this, and they know it. The first team that can deliver *provably correct* AI-generated code owns the category.

That is what we offer, and it has two halves that must move together: **better code and better specifications.** Code is only "correct" relative to a spec; a spec is only useful if the code provably meets it. We are the only team closing that loop.

## 2. What we offer (the loop nobody else can close)

We take the natural-language intent, derive a **formal specification** from it, and build on top of the best available code generators. Then comes the step that makes the difference: we **extract a specification back out of the generated code** and check it against the original intent and its formal spec. Where they disagree, *that disagreement is the bug* — we surface it, ask the developer to clarify, and converge. The end state is one where the natural-language intent, the formal spec, the generated code, and the spec re-extracted from that code **all say the same thing** — the evidence that it is the *right* code. Once spec and code are nailed down, we generate the **machine-checked proof of correctness** that seals it.

The case below is one full turn of that loop, on a real defect.

## 3. The bug a frontier model shipped on its own (baseline)

The task is a real `pytest` issue: *"Consider MRO when obtaining marks for classes."* Test "marks" attached to a class should be collected across its whole inheritance chain. The original code looked at only the first class in the hierarchy:

```python
# src/_pytest/mark/structures.py — original (buggy) get_unpacked_marks
mark_list = getattr(obj, "pytestmark", [])   # only THIS class's marks; ignores base classes
```

The frontier model, on its own, fixed the headline problem — it now walks the inheritance chain — but it walked it **in the wrong direction**:

```python
# baseline (V1): collects across the hierarchy, but base-class-first
for klass in reversed(obj.__mro__):
    mark_list.extend(getattr(klass, "pytestmark", []))
```

For a class `C(A, B)` whose members carry marks `c`, `a`, `b`, Python's method-resolution order (`__mro__`) is **derived-first**: `[C, A, B, object]`. The intended result is therefore `[c, a, b]`. Reversing the walk produces **base-first** `[b, a, c]`.

Here is the subtle part — **the ordinary tests did not catch it.** Every existing class-mark test was *set-based* (it checked *which* marks were present, e.g. `{m.name for m in iter_markers()}`), not their order. So the defect sailed through everything that was visibly green. It was caught only by the project's actual acceptance test, which pins the order:

```python
# testing/test_mark.py::test_mark_mro
assert get_unpacked_marks(C) == [xfail("c").mark, xfail("a").mark, xfail("b").mark]
# baseline result: [b, a, c]
# E  AssertionError: At index 0 diff: ...args=('b',) != ...args=('c',)
```

**Why the model failed here is the whole point.** It had no way to tell its plausible choice from the correct one. With no specification pinning the order and no order-sensitive test in front of it, it did the natural thing: it preserved what looked like prior behavior and rationalized it as *"required for backward compatibility."* Confident, reasonable-sounding, and wrong. This is the canonical failure mode of pure code generation — fluent code that satisfies the visible checks and quietly violates the one property that was never written down.

Evaluation: **baseline `resolved = False`** (FAIL_TO_PASS `test_mark_mro` 0/1).

## 4. What formal methods did (FVK)

Given the **same task and the same model**, FVK changed the process: before accepting the code, the model had to write down a **specification** of what `get_unpacked_marks` must do — the actual ordering obligation, derived from the issue's intent — and then **check the candidate code against that spec.**

Under that discipline, the "backward-compatibility requires this order" assumption did not survive. FVK's methodology treats a *"this choice is forced"* claim as a **hypothesis to falsify, not a premise**, and re-derives the behavior under *both* candidate orderings against the real obligations. The model's own audit notes (first-hand, from the run) record the moment the rationalization collapsed:

> *"All class-mark-merge tests are set-based (`{m.name for m in iter_markers()}`) … none pin merged-mark order … My V1 used `reversed(obj.__mro__)` … contradicting the maintainer's explicit `[mark1, mark4]`. That reversed order was justified only by preserving legacy ordering, which FVK forbids using as justification. The fix should use forward MRO."*

Because **both** orderings satisfied the (order-insensitive) legacy tests, the order was *under-determined, not forced* — so the only support for the wrong answer (preserve-the-legacy) was exactly the kind of evidence the formal discipline disallows. With the spurious justification gone, the intent-correct, MRO-natural order won:

```python
# FVK: forward MRO — derived-class-first, as the intent requires
for klass in obj.__mro__:
    mark_list.extend(getattr(klass, "pytestmark", []))
```

A one-token change — `reversed(obj.__mro__)` → `obj.__mro__` — but the *right* one, and arrived at because the specification said so, not because it looked plausible.

Evaluation: **FVK `resolved = True`** (FAIL_TO_PASS `test_mark_mro` 1/1, **PASS_TO_PASS 79/79** — no regressions). Same model, same problem; the difference was formal methods.

This is the discipline, quoted from the kit itself:

> *"'Forced' choices are hypotheses to falsify, not premises … re-derive the legacy / backward-compat trace under both candidates side by side … If both candidates satisfy the public obligations the choice is **under-determined, not forced** — record it as open, never as CONFIRM."*

## 5. Why only formal methods could catch this

Code by itself is ambiguous: it tells you *what the program does*, never *what it was supposed to do*. A frontier model produces fluent, plausible code all day — but plausibility is not correctness, and when intent is not written down, the model cannot distinguish a sound design decision from a confident rationalization. **A specification makes the intent explicit and checkable.** The instant you hold the code up against a real spec, a subtle defect stops being invisible and becomes a concrete contradiction: here, "the order is forced" was a falsifiable claim, and it was false. The disagreement between intent and implementation *is* the bug — and surfacing that disagreement is precisely what formal methods have done for safety-critical software for decades. We are putting that discipline underneath AI code generation, where it has never lived before.

## 6. From this rung to provably-correct code

This single result is one rung of the full ladder: derive the spec from intent, extract a spec from the generated code, reconcile the two, and converge. We demonstrated the rung that already changes the economics — **formal methods made a frontier AI measurably better at producing correct code, catching and fixing a bug it would otherwise have shipped, with zero regressions.** The remaining rungs are the same idea carried to its conclusion: full natural-language ↔ formal-spec ↔ code convergence, and then the machine-checked **proof** that turns "we checked it carefully" into "it is provably correct."

Nobody else is positioned to build this. This case is the existence proof that the approach works.
