# Constructed Proof

Status: constructed, not machine-checked. No K tooling was executed.

## Claims Proved

The claims are in `fvk/fits-fromstring-spec.k`; the fragment semantics are in
`fvk/mini-python-fits.k`.

- H-BYTES-STRSEP
- H-BYTES-BYTESEP
- H-STR
- C-BYTES
- C-STR

## Proof Sketch

### Header bytes data with text separator

Start state:

```k
<k> Header.fromstring(Bytes(DATA), Str(SEP)) </k>
requires ascii(DATA)
```

By the `Header.fromstring` semantic rule:

```k
parseHeader(decodeAscii(Bytes(DATA)), decodeAscii(Str(SEP)))
```

By `decodeAscii(Bytes(S)) => Str(S)` under `ascii(S)` and
`decodeAscii(Str(S)) => Str(S)`:

```k
parseHeader(Str(DATA), Str(SEP))
```

By the text parser abstraction:

```k
Header(DATA)
```

The bytes `TypeError` rules are unreachable because both inputs are text before
`parseHeader` is called. This discharges PO-1, PO-3, and PO-4 for ASCII bytes
data.

### Header bytes data with bytes separator

Start state:

```k
<k> Header.fromstring(Bytes(DATA), Bytes(SEP)) </k>
requires ascii(DATA) andBool ascii(SEP)
```

The same rewrite first reaches:

```k
parseHeader(decodeAscii(Bytes(DATA)), decodeAscii(Bytes(SEP)))
```

Both byte objects decode under the ASCII side condition:

```k
parseHeader(Str(DATA), Str(SEP))
```

Then the text parser abstraction returns:

```k
Header(DATA)
```

This discharges PO-2 in addition to PO-1 and PO-3.

### Header text preservation

Start state:

```k
<k> Header.fromstring(Str(DATA), Str(SEP)) </k>
```

The semantic rule calls `decodeAscii` on both arguments, and both calls are
identity rewrites for `Str`. The state therefore reaches:

```k
parseHeader(Str(DATA), Str(SEP)) => Header(DATA)
```

This discharges PO-4.

### Card bytes image

Start state:

```k
<k> Card.fromstring(Bytes(IMAGE)) </k>
requires ascii(IMAGE)
```

By the `Card.fromstring` semantic rule:

```k
makeCard(decodeAscii(Bytes(IMAGE)))
```

The ASCII bytes image decodes:

```k
makeCard(Str(IMAGE))
```

The text card abstraction pads and returns:

```k
Card(pad80(IMAGE))
```

This discharges PO-5 and PO-6.

### Card text preservation

For `Card.fromstring(Str(IMAGE))`, `decodeAscii(Str(IMAGE))` is identity, so the
existing text path reaches `Card(pad80(IMAGE))`. This discharges PO-6.

## Adequacy Gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `fvk/SPEC_AUDIT.md` marks
each paraphrase as passing against `fvk/INTENT_SPEC.md`. No claim proves legacy
bytes rejection, and no postcondition is derived solely from V1 implementation
behavior.

## Compatibility Gate

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no public signature, return-shape,
callsite, subclass, or producer/consumer incompatibility. The input domain is
expanded, not narrowed.

## Machine-Check Commands

These commands were not executed in this benchmark. They are the exact commands
to run later from the workspace root:

```sh
cd fvk
kompile mini-python-fits.k --backend haskell
kast --backend haskell fits-fromstring-spec.k
kprove fits-fromstring-spec.k
```

Expected machine-check result after a working K installation: `kprove` reduces
the claims to `#Top`.

## Test Redundancy Recommendation

No test removal is recommended. The proof is constructed, not machine-checked,
and existing FITS tests cover broad parser behavior outside this boundary
abstraction. Useful tests to keep or add later would include:

- `Header.fromstring` with ASCII bytes and default `sep`.
- `Header.fromstring` with ASCII bytes and `sep=b'\n'`.
- `Card.fromstring` with ASCII bytes.

