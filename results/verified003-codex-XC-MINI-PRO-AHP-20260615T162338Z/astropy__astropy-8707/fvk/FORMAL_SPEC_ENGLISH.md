# Formal Spec In English

Status: English paraphrase of the K claims in `fits-fromstring-spec.k`.

H-BYTES-STRSEP. For every ASCII byte string `DATA` and text separator `SEP`,
`Header.fromstring(Bytes(DATA), Str(SEP))` first decodes `DATA` to text and then
returns the same abstract header result as the text parser on `DATA`.

H-BYTES-BYTESEP. For every ASCII byte string `DATA` and ASCII byte separator
`SEP`, `Header.fromstring(Bytes(DATA), Bytes(SEP))` decodes both inputs to text
before parsing and returns the same abstract header result as the text parser on
`DATA`.

H-STR. For every text `DATA` and text `SEP`, `Header.fromstring(Str(DATA),
Str(SEP))` stays on the existing text parser path and returns the abstract
header result for `DATA`.

C-BYTES. For every ASCII byte string `IMAGE`, `Card.fromstring(Bytes(IMAGE))`
decodes the bytes to text, pads the text to an 80-character card boundary, and
returns the same abstract card result as text input.

C-STR. For every text `IMAGE`, `Card.fromstring(Str(IMAGE))` pads the text to an
80-character card boundary and returns the existing abstract card result.

Frame condition F-SIGNATURE. The formal model does not add arguments, change
return shapes, or introduce new public entry points.

Boundary condition B-NONASCII. Exact byte/text equivalence is claimed only for
ASCII bytes. Non-ASCII bytes follow the production `decode_ascii` warning and
replacement policy already used by binary file header reading.

