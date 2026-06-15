# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## What Is Proved

Under the mini semantics in `mini-python-enum.k`, the V1 implementation satisfies:

- For every modeled `TextChoices` or `IntegerChoices` member `Choice(NAME, V)`, the created-field string path reaches `valueText(V)`.
- For every retrieved primitive value `V`, the retrieved-field string path reaches `valueText(V)`.
- Therefore the created and retrieved paths produce the same external string output.
- For the public example `Choice("FIRST_CHOICE", SVal("first"))`, the created path reaches `text("first")`.
- The modeled enum representation path remains enum-name based.

## Proof Sketch

### PO2: Created Choice Stringification

Initial pattern:

```k
<k> CreateThenStr(Choice(NAME, V)) </k>
```

Symbolic execution:

1. Apply the creation-path rule:

```k
CreateThenStr(Choice(NAME, V)) => StrOf(Created(Choice(NAME, V)))
```

2. Apply the V1 stringification rule:

```k
StrOf(Created(Choice(NAME, V))) => valueText(V)
```

By transitivity:

```k
CreateThenStr(Choice(NAME, V)) => valueText(V)
```

This is exactly `Choices.__str__(self) = str(self.value)`.

### PO3: Retrieved Primitive Stringification

Initial pattern:

```k
<k> RetrieveThenStr(V) </k>
```

Symbolic execution:

1. Apply the retrieval-path rule:

```k
RetrieveThenStr(V) => StrOf(Retrieved(V))
```

2. Apply primitive stringification:

```k
StrOf(Retrieved(V)) => valueText(V)
```

By transitivity:

```k
RetrieveThenStr(V) => valueText(V)
```

### PO4: Created/Retrieved Equivalence

PO2 and PO3 end in the same post-state observable, `valueText(V)`, for the same concrete value `V`. Therefore created enum-member storage and retrieved primitive storage are equivalent for `str(field_value)`.

### PO5: Public TextChoices Example

Specialize PO2 with:

```k
NAME = "FIRST_CHOICE"
V = SVal("first")
```

The `valueText` simplification rule gives:

```k
valueText(SVal("first")) => text("first")
```

Therefore:

```k
CreateThenStr(Choice("FIRST_CHOICE", SVal("first"))) => text("first")
```

### PO6: Frame Conditions

V1 only adds `Choices.__str__`. It does not alter:

- `ChoicesMeta.__new__`;
- `.choices`, `.labels`, `.values`, `.names`;
- `.label` or `.value`;
- enum lookup by name/value;
- `__repr__`.

The formal frame claim `ReprOf(Choice(NAME, V)) => enumText(NAME)` models the preserved enum-name representation behavior independently of `StrOf`.

## Adequacy Gate

- `INTENT_SPEC.md` states the public intent before accepting V1 behavior.
- `FORMAL_SPEC_ENGLISH.md` paraphrases each K claim.
- `SPEC_AUDIT.md` marks each paraphrase as entailed by public intent.
- `PUBLIC_COMPATIBILITY_AUDIT.md` finds no public callsite or override requiring legacy enum-name `str()` output.

The proof therefore does not certify the reported bug as intended behavior.

## Reproduce The Machine Check Later

These commands are intentionally not run in this benchmark session:

```sh
cd fvk
kompile mini-python-enum.k --backend haskell
kast --backend haskell choices-str-spec.k
kprove choices-str-spec.k
```

Expected result after successful machine checking: `#Top`.

## Residual Risk

- This is a partial-correctness proof over a mini semantics, not a full Python or Django semantics.
- The proof is constructed, not machine-checked.
- The mini model abstracts integer string text as `intText(I)` but preserves the required equality between enum-member and primitive integer rendering.
- Custom concrete `Choices` subclasses inherit the new base `__str__`; this is covered as a compatibility observation rather than a separate full-domain proof for every concrete data type.

## Test Redundancy Recommendation

No test files were edited. Do not remove tests based on this constructed proof alone.

If the K claims are later machine-checked, point tests that only assert the in-domain created/retrieved `str()` equivalence for `TextChoices` and `IntegerChoices` may be considered subsumed by PO2-PO5. Keep metadata, integration, database round-trip, and compatibility tests.
