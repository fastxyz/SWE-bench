# Formal Spec English

Status: English paraphrase of the K claims; constructed, not machine-checked.

## K Claim Paraphrases

1. `CREATED-CHOICE-STR`
   - For every valid choice member `Choice(NAME, V)` in the modeled `TextChoices`/`IntegerChoices` domain, stringifying a freshly created field value that stores the enum member reaches `valueText(V)`.
   - `valueText(SVal(S))` is `text(S)`.
   - `valueText(IVal(I))` is the decimal text of the integer value, represented abstractly as `intText(I)`.

2. `RETRIEVED-PRIMITIVE-STR`
   - For every modeled primitive field value `V`, stringifying a retrieved field value reaches `valueText(V)`.

3. `CREATED-RETRIEVED-EQUIVALENCE`
   - For every choice member `Choice(NAME, V)`, the created path and retrieved path produce the same string-rendered observable: `valueText(V)`.

4. `CREATED-TEXTCHOICES-EXAMPLE`
   - For the public example value `Choice("FIRST_CHOICE", SVal("first"))`, stringifying the created field value reaches `text("first")`.

5. `REPR-FRAME`
   - The modeled representation operation for a choice member still returns an enum-name-style representation token and is not changed by the stringification rule.

## Modeled Implementation Link

The implementation rule corresponding to V1 is:

`Choices.__str__(self) = str(self.value)`

This maps directly to the K rule:

`StrOf(Created(Choice(NAME, V))) => valueText(V)`
