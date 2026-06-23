# astropy__astropy-14096

## Summary

**Severity:** Medium — baseline takes the wrong descriptor/MRO error path for a valid
subclass property whose provider sits after `SkyCoord` in the MRO, masking the real inner
`AttributeError`.

Baseline and FVK both passed the official SWE-bench evaluation for the "misleading
attribute access message" issue, but baseline truncates its subclass-property MRO scan at
`SkyCoord` (`if cls is SkyCoord: break`), so a custom property inherited from a mixin
ordered *after* `SkyCoord` still produces the misleading "no attribute" message. FVK (like
gold) honors the full Python MRO and reports the real missing inner attribute. FVK located
the gap by **formalizing the property-detection decision as "first MRO provider outside
`SkyCoord.__mro__`"** and auditing baseline's scan against it, not by running more tests.

| Arm | repro: `class C(SkyCoord, Mixin)` with a failing mixin property | Resolved |
|---|---|---|
| baseline | misleading `AttributeError: ... 'prop'` | no |
| gold (human oracle) | names real cause `random_attr` | yes |
| **fvk** | names real cause `random_attr` | **yes** |

(No harness `_proof` exists for this instance; verification is an executed source-level
demonstration — see §5.)

## 1. The issue and the real defect

The reported bug — *"Subclassed SkyCoord gives misleading attribute access message"*: a
`SkyCoord` subclass adds a `@property prop` that internally accesses a missing attribute
`random_attr`, and the raised error says `'custom_coord' object has no attribute 'prop'`
instead of naming `random_attr`
([`problem_statement.md`](../verified500_analysis/astropy__astropy-14096/_materials/problem_statement.md#L1)).

`SkyCoord.__getattr__` provides dynamic access to frame aliases and delegated frame
attributes. When a subclass property raises `AttributeError`, Python falls through to
`__getattr__("prop")`, whose generic fallback then reports that `prop` is missing — masking
the real inner `AttributeError(random_attr)` the property tried to read. The fix must
surface the inner error.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/solutions/solution_baseline.patch)
added an MRO walk at the start of `__getattr__` to detect a subclass-defined property and
re-invoke its descriptor so the inner error propagates. Its notes show a deliberate,
narrow scope:

> *"I limited the descriptor re-entry to `property` objects found before `SkyCoord` in the
> method-resolution order. This targets subclass-defined custom properties without changing
> the behavior of SkyCoord's own built-in properties …"*
> — [`reports/baseline_notes.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/reports/baseline_notes.md#L42)

The walk **breaks the moment it reaches `SkyCoord`** (`if cls is SkyCoord: break`). For
`class C(SkyCoord, Mixin)` the MRO is `[C, SkyCoord, …, Mixin, object]`, so a property
defined on `Mixin` (after `SkyCoord`) is never seen, and the misleading fallback returns.
The obligation baseline left unmet: **the property-detection decision must follow Python's
first MRO provider, not stop at `SkyCoord`.**

## 3. How FVK formally captured the gap

FVK started from an intent spec that names the contract, plus an evidence fact about
Python's object model that baseline's `break` violates:

> *"If that property raises `AttributeError` while trying to access an inner missing
> attribute, the final exception must identify the inner missing attribute, not the
> property name."*
> — [`fvk/SPEC.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/SPEC.md#L26)

> **E5:** *Python object model default-domain assumption — Normal attribute lookup honors
> the first class provider in MRO before `__getattr__`. → A custom property must win over
> `SkyCoord.__getattr__` fallback when it is the first MRO provider. Encoded in PO4.*
> — [`fvk/SPEC.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/SPEC.md#L42)

This discharges into a formal obligation that quantifies over the *full* MRO:

> **PO4: Respect Python MRO and exclude SkyCoord-owned properties.** *… The helper searches
> for the first class in `type(c).__mro__` whose `__dict__` contains `attr`. … If the first
> provider is outside `SkyCoord.__mro__` and its descriptor is a `property`, V2 treats it
> as a custom subclass property. If the first provider is in `SkyCoord.__mro__`, V2 does not
> intercept it.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/PROOF_OBLIGATIONS.md#L68)

This is the crux: the gap was located by **reasoning about MRO precedence**. The intent
says the inner error must survive; E5 says Python resolves the first MRO provider; so the
detection must scan the whole MRO and intercept any custom-property provider outside
`SkyCoord`'s hierarchy. Baseline's `break at SkyCoord` is exactly the violation.

## 4. From formal output to the fix

The repair is iterative, and the artifacts record the step where the formalism changed the
patch.

- **V1** stopped the scan at `SkyCoord` (identical to what baseline shipped) and recovered
  the inner error by replaying the descriptor.
- The completeness audit against the spec raised a finding:

  > **F3: V1's subclass-property scan stopped too early in the MRO.** *V1 stopped scanning
  > when it reached `SkyCoord`. A custom property supplied later in the MRO could be missed,
  > allowing the misleading SkyCoord fallback to remain.*
  > — [`fvk/FINDINGS.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/FINDINGS.md#L75)

- The iteration guidance turned the finding into the code decision:

  > *"The audit also justified broadening the MRO scan: Finding F3 showed that stopping at
  > `SkyCoord` could miss custom property providers elsewhere in the MRO. PO4 required using
  > the first MRO provider while excluding `SkyCoord`'s own hierarchy."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/ITERATION_GUIDANCE.md#L14)

- The decision log records the change and its provenance:

  > **D3: Scan the first Python MRO provider instead of stopping at `SkyCoord`.** *It scans
  > `type(self).__mro__` for the first class defining the attribute, then intercepts only if
  > that provider is outside `SkyCoord.__mro__` … F3 identified that V1 could miss custom
  > property providers inherited from a user-defined base class or mixin. PO4 requires Python
  > MRO precedence …*
  > — [`reports/fvk_notes.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/reports/fvk_notes.md#L35)

The causal chain is fully on the record:

```
SPEC intent 2  ->  E5 (Python resolves first MRO provider before __getattr__)
               ->  F3 (V1 audit: break at SkyCoord misses later providers)
               ->  PO4 (obligation: first MRO provider outside SkyCoord.__mro__)
               ->  ITERATION_GUIDANCE / D3  ->  V2 patch
```

FVK also added a saved-exception handoff (F2/PO2) so the failing property runs only once
instead of being replayed. The
[V2 patch](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/solutions/solution_fvk.patch)
scans the full MRO for the first provider and intercepts when it is a `property` outside
`SkyCoord.__mro__`. This matches gold's behavior — gold simply delegates the fallback to
`self.__getattribute__(attr)`, which naturally honors the full MRO. The `V1 -> V2`
transition was driven by `F3`/`PO4`, **not** by a new failing test — no test uses a mixin
ordered after `SkyCoord` (see §5).

## 5. Verification

**Executed source-level demonstration (not on the harness).** The MRO-scan logic was
reproduced from the patches and run on the mixin-after-SkyCoord layout:

```python
class Mixin:
    @property
    def prop(self):
        return self.random_attr        # attribute that does not exist
class C(SkyCoord, Mixin):
    pass
C(...).prop
```

| variant | error |
|---|---|
| **baseline** | `AttributeError: 'C' object has no attribute 'prop'` ← misleading (the exact bug) |
| **fvk / gold** | `AttributeError: ... 'random_attr'` names the real cause |

`class C(SkyCoord, Mixin)` (primary base first) is a normal, common inheritance layout —
not contrived. The FAIL_TO_PASS test only covers the simple direct-subclass case (property
on the immediate subclass, before `SkyCoord` in the MRO), which baseline's truncated scan
*does* reach — so baseline passes grading while retaining the defect.

**Gold comparison.** Gold delegates the fallback to `__getattribute__`, which honors the
full MRO; fvk explicitly scans the full provider chain. Both surface the inner error;
baseline's `break at SkyCoord` is the divergence. The secondary double-execution-of-property
difference (fvk runs the property once via the saved-error handoff; baseline replays it)
matters only if the property has side effects.

## 6. Boundaries & honesty

- **Severity: Medium.** The trigger breadth is a valid, common inheritance layout —
  `class C(SkyCoord, Mixin)` with the property provider after `SkyCoord` in the MRO. For
  that family baseline returns a misleading message that actively hides the real bug
  location; it does not corrupt data, hence Medium not High.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-python-attr.k`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/mini-python-attr.k),
  [`skycoord-attribute-access-spec.k`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/skycoord-attribute-access-spec.k))
  and the `kompile`/`kprove` commands were *written but never run* — the FVK artifacts say
  so explicitly
  ([`fvk/PROOF.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/PROOF.md#L3)).
  We claim **proof-structured reasoning**, not a machine-checked proof.
- **Attribution.** This instance has no harness `_proof`; verification is the executed
  source-level demonstration above, reproduced from the patch deltas — not an official
  SWE-bench Docker RED/GREEN run. The `V1 -> V2` iteration is documented across
  `FINDINGS.md`, `ITERATION_GUIDANCE.md`, and `fvk_notes.md`. The verified descriptor
  domain is Python `property` only (F4); arbitrary descriptors are out of scope.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, repro | [`_materials/problem_statement.md`](../verified500_analysis/astropy__astropy-14096/_materials/problem_statement.md#L1) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/solutions/solution_baseline.patch) |
| Baseline reasoning | [`reports/baseline_notes.md`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/reports/baseline_notes.md#L42) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/solutions/solution_fvk.patch) |
| Gold patch | [`_materials/gold.patch`](../verified500_analysis/astropy__astropy-14096/_materials/gold.patch) |
| Intent (inner error must survive) | [`fvk/SPEC.md#L26`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/SPEC.md#L26) |
| Evidence E5 (MRO precedence) | [`fvk/SPEC.md#L42`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/SPEC.md#L42) |
| Obligation PO4 | [`fvk/PROOF_OBLIGATIONS.md#L68`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/PROOF_OBLIGATIONS.md#L68) |
| Finding F3 | [`fvk/FINDINGS.md#L75`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/FINDINGS.md#L75) |
| Iteration decision (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L14`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/ITERATION_GUIDANCE.md#L14) |
| Decision trace D3 | [`reports/fvk_notes.md#L35`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/reports/fvk_notes.md#L35) |
| Constructed K core | [`fvk/mini-python-attr.k`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/mini-python-attr.k), [`fvk/skycoord-attribute-access-spec.k`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/skycoord-attribute-access-spec.k) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L3`](../results/verified001-codex-XC-MINI-PRO-AHP-20260615T131050Z/astropy__astropy-14096/fvk/PROOF.md#L3) |
