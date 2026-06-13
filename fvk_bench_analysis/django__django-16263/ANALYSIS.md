# ANALYSIS — django__django-16263 (FVK arm)

- **Instance:** `django__django-16263` · **Batch:** `batch3-XC-MINI-PRO-AHP-260613154559`
- **Outcome:** FAIL (partial pass). `resolved: false`. **FAIL_TO_PASS = 1 pass / 2 fail**, plus **1 PASS_TO_PASS regression**. fvk verdict identical to baseline (zero flip).
- **VERDICT (this instance): MISSING — but reachable.** Counts toward headroom? **No** (MISSING). It is an FVK *gap*, not an information-theoretic dead end.

Evidence: `./evidence/oracle.patch.diff`, `./evidence/solution_baseline.patch`, `./evidence/solution_fvk.patch`, `./evidence/EXCERPTS.md`.

---

## 1. Root cause (incl. which F2P still failed)

**Ticket.** `QuerySet.count()` (and `.exists()`) should ignore annotations not referenced by filters/ordering/grouping/other annotations, so e.g. `Book.objects.annotate(Count('chapters')).count()` does not drag the unused `Count` (and its needless GROUP BY/subquery) into the SQL. Optimization must not change the returned value (`count() == len(qs)`).

**True bug site (oracle):** `django/db/models/sql/query.py :: Query.get_aggregation` (~L441 at base `321ecb40f4`). The pre-fix guard decides whether to wrap in a subquery / GROUP BY from the mere *presence* of any existing annotation (`existing_annotations` truthy), with the comment "we aren't smart enough to remove the existing annotations from the query, so those would force us to use GROUP BY." Hence unused annotations leak into `count()` SQL.

**Bug TYPE:** missing-optimization / **over-broad (wrong) condition** — guard tested annotation *presence* instead of *referenced aggregation usage*.

**Correct fix (oracle).** Do NOT physically delete annotations. Instead (see `evidence/EXCERPTS.md` E2):
- Compute `existing_annotations` from `annotation_select` only, and a new `has_existing_aggregation = any(contains_aggregate or contains_over_clause ...) or any(self.where.split_having_qualify()[1:])`; gate subquery/GROUP-BY on **usage**, not presence.
- In the subquery branch, **keep the subquery** but `inner_query.set_annotation_mask(...)` built from `annotation.get_refs()` so the unreferenced annotation's alias vanishes from SELECT.
- In the no-subquery branch, inline referenced annotations via `Ref(alias, annotation): annotation` `replace_expressions`, then `set_annotation_mask(added_aggregate_names)`.
- Supporting: new `get_refs()` on `BaseExpression`/`Ref` (`expressions.py`) and `WhereNode` (`sql/where.py`); a `summarize` flag threaded through `query_utils.py`/`query.py`.

**Which F2P remained FAILING and why** (the headroom-relevant crux). The SQL **shape** is the contract — the hidden tests assert `sql.count("select")`:

1. **`test_unreferenced_aggregate_annotation_pruned`** — `Book.objects.annotate(authors_count=Count("authors")).count()` asserts `sql.count("select") == 2` ("Subquery wrapping required") and `authors_count` absent. **fvk got `1 != 2`.** fvk's design *deletes* the aggregate and unrefs its M2M join, collapsing to a single `SELECT COUNT(*) FROM book`. Gold instead **keeps** the COUNT(*)-over-subquery (the grouped subquery is what makes `count()` equal distinct-book count over a multi-valued join) and only **masks** the alias. fvk removed too much.

2. **`test_unused_aliased_aggregate_pruned`** — `Book.objects.alias(authors_count=Count("authors")).count()` asserts `sql.count("select") == 1` ("No subquery wrapping required"). **fvk got `2 != 1`.** Mirror image: fvk's strip pass iterates only `annotation_select` and deliberately keeps `alias()`-only (unselected) annotations, so the aggregate's GROUP BY/subquery survives. Gold's usage-gate yields a flat single SELECT. fvk removed too little. So fvk fails **both directions** of the aggregate contract.

3. (Regression) **`test_aggregation_subquery_annotation_multivalued`** (P2P) — `author_qs.count() == Author.objects.count()` gives `10 != 9`. The join-unref'ing on a multivalued subquery-annotation count drops a GROUP-BY-relevant join → over-count. Present in baseline AND fvk; control avoids it. A third symptom of the same wrong architecture.

The one F2P that **passed** (`test_non_aggregate_annotation_pruned`, `Lower("name")`, base-table only) is the lone case where "delete the annotation" happens to coincide with gold's "collapse to 1 SELECT." So fvk got the easy non-aggregate case and missed both aggregate cases.

**Public-data reachability.** The *what* is fully public and even region-pinned: the problem statement says to strip annotations "not referenced by filters, other annotations or ordering" and links `django/db/models/sql/query.py#L404-L414` plus PRs #8928/#11062. The *exact SQL-shape contract* (2 SELECTs for an unreferenced aggregate; 1 for an alias-only aggregate; the multivalued-GROUP-BY correctness coupling) is **not** in the materials — the prompt does not embed the hidden tests, and a hint anecdote even nudges toward the wrong "collapse to a single SELECT" strategy. So the *category* (annotation-pruning in `query.py`, aggregate vs non-aggregate, GROUP-BY correctness on multivalued joins) is reachable; the precise remedy is derivable by careful reasoning but not handed over. -> **MISSING-but-reachable** (a competent reasoner with the public issue + Django ORM knowledge could have reached the gold design; nothing information-theoretically blocked it).

---

## 2. What the fvk arm did (V1 vs final + key artifacts)

**Architecture (V1 = baseline, inherited).** Rather than touch `get_aggregation`, V1 added a helper cluster (`_gen_annotation_refs`, `_get_referenced_annotation_aliases`, `_unref_annotation_joins`, `_strip_unused_annotations`) and called `_strip_unused_annotations({"__count"})` inside `get_count` *before* `get_aggregation`, plus reworked the `exists()` GROUP-BY branch. The strategy: physically **delete** unreferenced selected annotations + their joins so `get_aggregation` "naturally collapses to `SELECT COUNT(*)`."

**fvk = confirm, not change.** `diff solution_baseline.patch solution_fvk.patch` (evidence E6) shows fvk added exactly **two** things on top of V1:
1. `_annotation_is_strippable(annotation)` (returns `True` for any aggregate, or a non-aggregate introducing no non-base join) and gated `unused` on it — the F1 fix for multi-valued *non-aggregate* annotations.
2. `self.distinct_fields` added to the reference scan — the F2 fix.

Both are **orthogonal** to the two failing aggregate tests and to the multivalued P2P regression. FAIL_TO_PASS stayed 1/3. fvk did not change the architecture; it audited and blessed it.

**Key artifact contents.** Six markdown files; **no `.k` files on disk** (the `mini-orm.k`/`-spec.k` source is quoted only inside `PROOF.md`). The artifacts are internally rich and self-consistent, built around a **mini-ORM** abstraction whose state tracks a row COUNT (an integer: `B | |distinct G-tuples| | B*Pi fanout`) and a governing contract `count() == len(list(qs))`. Findings F1 (the multi-valued non-aggregate bug) and F2 (distinct_fields) drove the two V2 edits; F6/F7/F9 mark the rest as POSITIVE confirmations of V1. PO1–PO6 "discharged" (constructed, not machine-checked); PO7 / PD5 = `[ESCALATION BOUNDARY]` on mini-ORM<->SQL adequacy.

**Transcript.** The agent Read the gold-patch files repeatedly (`sql/query.py` x31, `expressions.py` x8, `query_utils.py` x1, `sql/where.py` x2), briefly **edited `get_aggregation` toward the gold approach, then explicitly reverted** it as "too risky for `aggregate()`," scoping the strip to `get_count`. It also made the (no-exec) bet that "no existing test asserts subquery/GROUP BY presence in `count()`/`exists()` SQL" — exactly what the hidden tests assert. (Evidence E7.) This is a reasoning/decision miss, not a coverage miss.

---

## 3. Artifact audit — VERDICT

### VERDICT: **MISSING — but reachable.** (Does not count toward headroom; is an FVK gap.)

The actual root-cause **mechanism/condition the oracle fixes is absent**, and where the artifacts touch the buggy region they **invert it and certify the buggy behavior as correct**. This is primer **tell #7 (scope-induced false-negative)** in its strongest form, plus a decoy overlay (a confident "proof of correctness" for the wrong design — the inverse of "hard spec => bug").

**What is genuinely present (the region is named):** the artifacts sit on count/exists annotation handling in `query.py`, use the correct `contains_aggregate` discriminator, and even quote the failing scenarios' inputs (`annotate(Count(...)).count()`, `alias(...)`). To that extent FVK localized to the right file.

**Why it is nonetheless MISSING on the *cause* (pointed-at-the-spot applied to the remaining failure):**

1. The condition the oracle encodes — "an unreferenced *aggregate* annotation must be **removed from SELECT while the COUNT(*) subquery is retained**" — is **contradicted**. `SPEC.md:9-13` and `FINDINGS.md:100-106` (F6, marked POSITIVE) assert the correct output is the single-SELECT `SELECT COUNT(*) FROM book`. That is the literal value `test_unreferenced_aggregate_annotation_pruned` rejects (`1 != 2`). A reader pointed here finds the *wrong* answer asserted as correct, not the cause. (Evidence E3.)

2. The condition "**unselected `alias()` aggregates must also be pruned**" is **explicitly negated** — `FINDINGS.md:118-124` (F8) and `solution_fvk.patch:123-125` keep them "for safety." That decision *is* the cause of `test_unused_aliased_aggregate_pruned`, narrated as a deliberate safe choice, not a defect. (Evidence E4.)

3. The gold machinery — `has_existing_aggregation`, `get_refs()`, `Ref`-inlining in `get_aggregation`, `contains_over_clause`, `split_having_qualify`, `set_annotation_mask` — appears **nowhere** in any artifact or in the visible transcript (keyword scan: `has_existing_aggregation` = 0, `Subquery wrapping`/`count("select")` = 0). (Evidence E2 vs E7.)

4. The only formal object that could expose the failure — the number-of-SELECTs / subquery-presence distinction the tests measure — is **abstracted away** by the mini-ORM `rowcount` integer model and then fenced as `[ESCALATION BOUNDARY]` (`SPEC.md:34-36`, `FINDINGS.md:158-160` PD5). Per kit policy (primer §v#2, §vi), an escalation boundary on a capability gap is a KIT limitation, not a code-bug finding — so this does **not** rescue the verdict to BURIED. The signal was *defined out of scope* before any obligation could land on it.

**Not BURIED:** BURIED requires the signal to exist in formal form (a forced `requires`, an undischargeable obligation on the buggy branch, a spec/intent divergence on the graded defect). Here the relevant obligations are all marked "discharged" *for the wrong target*, and the one boundary is a kit-capability gap, not a VC sitting on the buggy value. There is no latent-correct fingerprint to surface — the formalism actively endorses the bug.

**Not STATED (and not tell #8):** tell #8 requires the artifact to *name the correct fix and argue against it*. The agent did momentarily move toward the gold path in the transcript and then reverted it (E7) — but it reverted to avoid `aggregate()` regressions, not by quoting and rejecting the *oracle's actual remedy* (mask-not-delete, usage-gated subquery). No artifact states "keep the subquery and mask the alias" as the alternative. The closest is the transcript's mistaken assumption that no test checks SQL shape — an absence-of-information bet, not a stated-and-rejected fix. So this is weaker than STATED.

**Honesty (PLAN §4 reachability check):** the cause IS derivable from public data (issue + Django ORM semantics point at `query.py` annotation pruning and the aggregate/GROUP-BY correctness coupling), so the absence **is** an FVK gap — just not one that counts toward headroom, because the information is not latent in the artifacts FVK produced. MISSING-but-reachable.

---

## 4. How FVK could surface it (prose, general, no-exec)

1. **Don't let the abstraction erase the property under audit.** The mini-ORM modeled only an integer row-count and explicitly dropped subquery/GROUP-BY *shape* — but for `count()`/`exists()` optimizations the SQL **shape** (how many SELECTs, whether a grouping subquery is retained) is load-bearing because it is what preserves correctness over multi-valued joins. A general guard: when the issue is "optimize the *generated query* while preserving a value," the spec's observable must include the query structure being optimized, not just the scalar result. An abstraction that abstracts away the exact axis the change manipulates makes every obligation vacuous (primer tell #7 / §viii "total is vacuous").

2. **Treat "no test asserts X" as an obligation to write, not a license.** The arm rejected the gold path partly on the belief that nothing checks SQL shape. In the no-exec paradigm, an unverifiable assumption like "stripping the aggregate cannot change observable behavior" should become an explicit PO ("PO: dropping a multi-valued aggregate join does not change `len(qs)`") whose discharge would have *forced* the case split that distinguishes alias-only vs selected aggregates — exactly the F1/F8 boundary the patch got wrong.

3. **Surface the rejected-then-reverted alternative as a finding.** The transcript shows the agent reaching the gold site (`get_aggregation`) and retreating "for safety." That decision — and the *untested* risk it traded against — should have been written into ITERATION_GUIDANCE as an open obligation ("V1 strips in `get_count`; the value-preserving alternative is masking in `get_aggregation` — undischarged: does deletion change multi-valued counts?"). Surfacing rejected alternatives with their open risk is the de-noising step that would have re-opened the right question.

4. **Cross-check the intent ledger against the *full* issue, including misleading hints.** The hint anecdote nudged toward "collapse to one SELECT." A disciplined intent ledger that separated *what the ticket wants* (no unused annotation in SQL) from *one commenter's "good enough" anecdote* would have prevented baking the single-SELECT target into SPEC.md as the governing postcondition (`SPEC.md:9-13`).

*(Recommendations stay prose-level and within the no-exec paradigm.)*
