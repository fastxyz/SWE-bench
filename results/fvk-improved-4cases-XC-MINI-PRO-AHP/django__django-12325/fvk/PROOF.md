# PROOF.md — constructed correctness proof for the V1 parent-link selection

**Status: constructed, not machine-checked.** The `.k` artifacts
([`mini-python.k`](mini-python.k), [`parent-links-spec.k`](parent-links-spec.k))
plus the `kompile`/`kprove` commands in §8 are what would upgrade this to
machine-verified. Findings are independent of machine-checking.

Notation: `L = b_1 : … : b_n : .BList` is the in-order flag list for one parent
(see SPEC §6 for why one symbolic per-key list is sufficient). The proved object
is the loop selecting `chosen` (1-based position, `0`=None) and `cpl` (chosen's
flag).

## 1. What is proved

For every flag list `L`, the V1 loop, **if it terminates** (it always does — it
consumes `local_fields`), ends with

```
chosen = selectResult(L) =  firstTrue(L)            if containsTrue(L)
                            lenB(L)                 else if lenB(L) > 0
                            0                       else
cpl    = containsTrue(L)
```

i.e. **the first explicit `parent_link=True` field wins; otherwise the last
field; otherwise none** — the contract `(SELECT)`.

## 2. Semantics steps used (from `mini-python.k`)

`seqstrict`/heating evaluates `head/tail/isEmpty/not/and/or/==/+` on values; the
matching rule fires; `if(true|false)` and the `while`→`if` unrolling drive the
loop; assignment updates `<store>`. These micro-steps are the paper
`(lookup)/(head)/(leq)/(store)` steps. Cells/bindings not mentioned are carried
by framing.

## 3. Concrete instances (no induction — direct symbolic execution)

### (CASE-A) `L0 = true : false : .BList` — `document_ptr` before `origin`
Init `chosen=0, cpl=false, j=1`.
- **Iter 1** `l=[T,F]`: `isEmpty=false`; `h=true`. Guard `chosen==0 or not cpl =
  (0==0) or … = true` ⇒ store `chosen=1, cpl=true`. `l=[F]`, `j=2`.
- **Iter 2** `l=[F]`: `h=false`. Guard `chosen==0 or not cpl = false or (not
  true) = false` ⇒ **skip**. `l=.BList`, `j=3`.
- **Exit** `isEmpty=true`. ⇒ `chosen=1, cpl=true, j=3`. ∎ matches `(CASE-A)`.

`chosen=1` = the `parent_link=True` field. **O1 holds (failing order fixed).**

### (CASE-B) `L0 = false : true : .BList` — `origin` before `document_ptr`
- **Iter 1** `l=[F,T]`: `h=false`. Guard `(0==0) or … = true` ⇒ store
  `chosen=1, cpl=false`. `l=[T]`, `j=2`.
- **Iter 2** `l=[T]`: `h=true`. Guard `chosen==0 or not cpl = false or (not
  false) = true` ⇒ store `chosen=2, cpl=true`. `l=.BList`, `j=3`.
- **Exit** ⇒ `chosen=2, cpl=true`. ∎ matches `(CASE-B)`.

`chosen=2` = the `parent_link=True` field again. **Winner is order-independent
(O1).** (CASE-A)+(CASE-B) together are the reported bug, fixed both ways.

### (CASE-LONE) `L0 = false : .BList`
- **Iter 1**: `h=false`. Guard true ⇒ store `chosen=1, cpl=false`. `l=.BList`.
- **Exit** ⇒ `chosen=1, cpl=false`. ∎ The field is selected, so
  `Options._prepare()` runs `if not field.remote_field.parent_link: raise
  ImproperlyConfigured('Add parent_link=True …')`. **O2 holds.**

## 4. General contract via the `(LOOP)` circularity

`(LOOP)` is proved by guarded coinduction; the genuine `=>⁺` step is the guard
evaluation each iteration, so K may use `(LOOP)` on the shifted state.

Invariant closed form `remainResult(C,P,J,L)` (SPEC / spec.k): if `C≠0 ∧ P`
(a parent link already locked) the result is `C`; else the first `True` in `L`
at absolute position `J−1+firstTrue(L)`, else the last at `J−1+lenB(L)`, else
`C`.

**Base** `L=.BList`: `while` exits, `chosen=C`. Both `remainResult` branches give
`C` (the `C≠0∧P` branch is `C`; otherwise `containsTrue(.BList)=false ∧
lenB=0` ⇒ `C`). ✓

**Step** `L = h:T`, position `J`. Evaluate the guard (the guard step is the
guardedness obligation), then case-split:

- **KEEP** `C≠0 ∧ P`: guard `C==0 or not P = false or false = false` ⇒ no store;
  `l=T, j=J+1`. Invoke `(LOOP)` on `(C,P,J+1,T)`: still `C≠0∧P` ⇒ `C`. And
  `remainResult(C,P,J,h:T)=C`. ✓
- **STORE** `C=0 ∨ ¬P`: guard true ⇒ `chosen=J, cpl=h`; `l=T, j=J+1`. Invoke
  `(LOOP)` on `(J,h,J+1,T)` and compare to `remainResult(C,P,J,h:T)` (with
  `¬(C≠0∧P)`), splitting on `h`:
  - `h=true`: recursion ⇒ `J` (since `J≥1≠0 ∧ true`). Target:
    `containsTrue(true:T)=true` ⇒ `J−1+firstTrue(true:T)=J−1+1=J`. ✓
  - `h=false`: recursion ⇒ (since `J≠0∧false=false`) `containsTrue(T) ?
    J+firstTrue(T) : (lenB(T)>0 ? J+lenB(T) : J)`. Target:
    `containsTrue(false:T)=containsTrue(T)`; if true `J−1+firstTrue(false:T)=
    J−1+(1+firstTrue(T))=J+firstTrue(T)` ✓; else `J−1+lenB(false:T)=J+lenB(T)`,
    matching `J+lenB(T)` for `T≠.BList` and `J` for `T=.BList` (`lenB(T)=0`). ✓

All branches land on the claimed post-state. Setting `(C,P,J,L)=(0,false,1,L0)`
gives `(SELECT)`: `remainResult(0,false,1,L0)=selectResult(L0)` and final
`cpl=containsTrue(L0)`. ∎

### Cross-base scenarios (O5b)
Processing order is parents-(reversed)-then-`new_class`, so an abstract base's
fields precede the child's in `L`.
- **X**: abstract has a plain OTO, child has the marked one ⇒ `L=[false,…,true,…]`
  ⇒ lock occurs at the child's marked field ⇒ **child's parent_link wins**. ✓
- **Y**: abstract has the marked OTO, child has a plain one ⇒ `L=[true,…,false]`
  ⇒ locked at the abstract field, never overwritten ⇒ **abstract parent_link
  wins** (= `test_abstract_parent_link`, E9). ✓

## 5. Frame proof (O5) — change is confined to the ambiguous case

Let `last(L)` be the pre-V1 result ("last write wins", i.e. `lenB(L)` for
non-empty `L`, else `0`). Then `selectResult(L) ≠ last(L)` **iff**
`containsTrue(L) ∧ firstTrue(L) ≠ lenB(L)` — i.e. there is a marked field and the
last field is not that first marked field. Equivalently: at least two OTOs target
the parent and a `parent_link=True` one is not declared last. Every other input
(`containsTrue(L)=false`, or a single field, or empty) yields
`selectResult(L)=last(L)` exactly. So V1 is behaviorally identical to the
original everywhere except the precise multiple-reference ambiguity the issue
reports. **O5 holds; O4 (unmarked multiples ⇒ last) is the `containsTrue=false`
sub-case.** ✓

## 6. Consumer trace (O5c, pk consistency)

`base.py:248` `if base_key in parent_links: field = parent_links[base_key]` →
`new_class._meta.parents[base] = field`. `options.py:_prepare()`:
`field = next(iter(self.parents.values()))`; `field.primary_key = True`;
`setup_pk(field)`; `if not field.remote_field.parent_link: raise …`. With V1,
`field` is the `parent_link=True` field, so (a) it becomes the pk and (b) the
guard passes — no error, and the parent-pointer column == pk, populated. This is
exactly the "model still broken / `document_ptr_id` not populated unless field
order is correct" complaint, now order-independent. ✓

## 7. Side-by-side derivation of the rejected alternative (O6 / F-ALT)

Hypothesis to falsify: replace V1 with **filter** —
`if isinstance(field, OneToOneField) and field.remote_field.parent_link:` (i.e.
collect *only* marked fields). Model: `selectResult'(L)= firstTrue(L)` if
`containsTrue(L)` else `0` (unmarked fields are never stored).

| Input `L` | V1 `selectResult` | Alt `selectResult'` | Public obligation |
|-----------|-------------------|----------------------|-------------------|
| `[true,false]` (CASE-A) | `1` (marked) | `1` (marked) | O1 — both ✓ |
| `[false,true]` (CASE-B) | `2` (marked) | `2` (marked) | O1 — both ✓ |
| `[false]` (lone, E8) | `1` ⇒ `_prepare` **raises** `Add parent_link=True` | `0` ⇒ key absent ⇒ **auto-creates `…_ptr`, no error** | **O2/E6** — V1 ✓, **Alt ✗** |
| `[]` | `0` ⇒ auto link | `0` ⇒ auto link | O3 — both ✓ |

The two candidates agree on the reported case (O1) but **diverge on the lone
unmarked field**: the alternative makes the `Add parent_link=True` error in
`options.py` unreachable and silently injects a `…_ptr` column — contradicting
the documented deprecation (E6, "implicit promotion … removed; *add*
`parent_link=True`") and `test_missing_parent_link` (E8). Therefore the
alternative **fails a public obligation (O2)**; V1's choice is *forced*, not
merely preferred. (The single-token hint E3 points at the right field to inspect
but, taken literally as a filter, over-reaches; V1 realizes E3's intent —
"consult `parent_link`" — as a *priority* rather than a *filter*.)

## 8. Run-commands (to machine-check later)

```sh
kompile mini-python.k --backend haskell          # compile the fragment semantics
kast    --backend haskell parent-links-spec.k    # (optional) confirm the spec parses
kprove  parent-links-spec.k                       # discharge all claims; expected: #Top
```

Expected: `(CASE-A)`, `(CASE-B)`, `(CASE-LONE)` discharge by concrete symbolic
execution; `(SELECT)` reduces to `(LOOP)` instantiated at `(0,false,1,L0)`;
`(LOOP)` discharges by the §4 coinduction with linear position-arithmetic VCs
(`J≥1 ⇒ J≠0`, `J−1+1=J`, `J−1+(1+k)=J+k`) and the definitional unfoldings of
`containsTrue/firstTrue/lenB` on `h:T`.

## 9. Residual risk / trusted base

- **Partial correctness** (N1): termination of the `local_fields` loop is
  evident but not part of the proved contract.
- **Trusted base:** adequacy of the mini-python fragment (the per-key abstraction
  in SPEC §6), the reachability/coinduction metatheory + `kprove`, and the
  arithmetic oracle for the linear VCs.
- **Constructed, not machine-checked:** §8 commands not executed in this
  environment.

## 10. Verdict

All MUST obligations (O1–O3, O5, O5b, O6, O7) discharge; O4/O5c hold; O6 falsifies
the only named alternative against O2. **V1 is correct and adequate; it stands
unchanged.** Benefit-2 findings are in [`FINDINGS.md`](FINDINGS.md).
