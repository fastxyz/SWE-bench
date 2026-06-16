# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation reasoning only.

## F-001: V1 fixes the reported signature-introspection defect

- Input: any eligible queryset method `method` copied onto a generated manager,
  including `QuerySet.bulk_create()`.
- Pre-fix observed: the generated manager method exposed the proxy signature
  `(*args, **kwargs)` when bound, because only `__name__` and `__doc__` were
  manually copied.
- Expected: `inspect.signature()` on the bound manager method exposes the
  original queryset method's bound signature.
- V1 observed by source audit: `@wraps(method)` gives the proxy a `__wrapped__`
  link to the queryset method. Python introspection follows that link and then
  applies bound-method receiver removal.
- Classification: confirmed fix; no additional source edit required.
- Related obligations: PO-001, PO-002, PO-003.

## F-002: The expected parameter list must be generic, not hard-coded to the issue example

- Input: `QuerySet.bulk_create()` in this checkout.
- Observed source: the current signature is
  `(self, objs, batch_size=None, ignore_conflicts=False, update_conflicts=False,
  update_fields=None, unique_fields=None)`.
- Issue example: the expected signature shown in the public report omits the
  later conflict-update parameters.
- Expected specification: the manager signature equals the current queryset
  method signature with `self` bound away, whatever that current signature is.
- Classification: spec adequacy finding; V1 is correct because `wraps()` tracks
  the callable rather than a fixed `__signature__` value.
- Related obligations: PO-001, PO-004.

## F-003: Method selection and runtime forwarding are unchanged

- Input: queryset methods that are private, marked `queryset_only=True`, already
  present on the manager class, or marked `queryset_only=False`.
- Observed source: V1 changes only metadata assignment inside `create_method()`;
  the filtering loop and the forwarding call expression are unchanged.
- Expected: the fix must not copy additional methods or alter manager method
  call behavior.
- Classification: frame condition satisfied.
- Related obligations: PO-004, PO-005.

## F-004: `functools.wraps()` copies more metadata than the previous manual assignment

- Input: queryset methods with attributes such as `alters_data`,
  `queryset_only=False`, annotations, module, or qualname metadata.
- Pre-fix observed: only `__name__` and `__doc__` were copied.
- V1 observed by source audit: `wraps()` copies the default wrapper metadata and
  updates the wrapper dictionary.
- Expected: the public issue explicitly identifies incomplete metadata copying
  as the defect, so this broader metadata copy is intended rather than an
  accidental API expansion.
- Classification: compatible intended behavior; no source change required.
- Related obligations: PO-002, PO-006.

## F-005: Proof is constructed but not machine-checked

- Input: the abstract K-style claims in this FVK package.
- Observed: no `kompile`, `kast`, `kprove`, Python, or test command was run.
- Expected: commands are recorded in `PROOF.md` for later human execution in an
  environment that has the tooling.
- Classification: honesty-gate residual risk, not a code bug.
- Related obligations: PO-007.
