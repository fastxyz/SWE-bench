# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Intent adequacy

The formal claims must state the public issue's required behavior, not merely
the candidate implementation's behavior.

Evidence: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, and `SPEC_AUDIT.md`.

Status: discharged. `PROXY-ONLY-PK` matches the issue's required absence of the
`ValueError`, and `LEGACY-PROXY-COUNTEREXAMPLE` is explicitly marked as a
counterexample rather than desired behavior.

## PO2: Concrete-target mask invariant

After following a relation to target model `T`, `deferred_to_data()` must add the
related target primary key under `T._meta.concrete_model`, not under `T` when
`T` is a proxy.

Evidence: `django-deferred-spec.k` claim `PROXY-ONLY-PK`.

Status: discharged by the V1 line `cur_model = cur_model._meta.concrete_model`.

## PO3: Only-mode merge invariant

In `only()` mode, `must_include` fields must merge into the same model key as
the requested related fields. For the proxy issue shape, the key is
`CustomModel`.

Evidence: `django-deferred-spec.k` claim `PROXY-ONLY-PK` and
`FINDINGS.md` entry `F1`.

Status: discharged. The fixed traversal state makes the required primary key
and requested field share the concrete model key.

## PO4: Selection and population compatibility

The model key used in the load mask must match the key used by
`get_default_columns()` when checking `field.model in only_load`, so the
selected related columns include `model_cls._meta.pk.attname` before
`RelatedPopulator` computes `pk_idx`.

Evidence: `PUBLIC_EVIDENCE_LEDGER.md` entries `E6` and `E7`;
`django-deferred-spec.k` claim `PROXY-ONLY-PK`.

Status: discharged. The formal selected field set contains `idField`.

## PO5: Frame condition for non-proxy targets and public API

Normalizing relation targets must not change concrete-target behavior or public
API compatibility.

Evidence: `CONCRETE-TARGET-FRAME` and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Status: discharged. For a concrete target, `concrete(T) = T`; no signatures,
call protocols, or test files changed.

## PO6: Legacy counterexample eliminated

The formal model must be able to derive the reported failure from the pre-fix
mechanism and show that V1 removes that mechanism.

Evidence: `LEGACY-PROXY-COUNTEREXAMPLE`, `PROXY-ONLY-PK`, and
`FINDINGS.md` entry `F1`.

Status: discharged. The legacy counterexample omits `idField` from concrete
default-column selection; the fixed claim includes it.

