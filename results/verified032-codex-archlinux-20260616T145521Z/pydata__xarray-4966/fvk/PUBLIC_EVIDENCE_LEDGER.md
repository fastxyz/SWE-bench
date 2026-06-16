# Public Evidence Ledger

Status: public evidence only; no hidden tests, internet, or evaluator data used.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "netCDF3 only knows signed bytes... `_Unsigned=True` ... store unsigned bytes" | Signed integer storage plus true marker decodes to unsigned integer values. | Encoded in SPEC and K claims. |
| E2 | problem | "OPeNDAP only knows unsigned bytes... `_Unsigned=False` ... store signed bytes" | Unsigned integer storage plus false marker decodes to signed integer values. | Encoded in SPEC and K claims. |
| E3 | problem | "`if .kind == \"u\" and unsigned == False`" | The false-marker case must include explicit boolean `False`, not only string `"false"`. | V1 gap; V2 code edit. |
| E4 | problem example | netcdf4 output includes `-128.0 -1.0 ... 127.0`; pydap output incorrectly includes `128.0 255.0 ... 127.0` | One-byte unsigned values `128` and `255` must map to signed `-128` and `-1` before scale/mask output. | Encoded in cast postcondition. |
| E5 | problem | "pydap doesn't [handle this internally]... xarray returns a warning at exactly the location referenced above" | The shared xarray CF decoder is the repair location; backend-specific normalization is not required. | Encoded in file choice and compatibility audit. |
| E6 | source docstring | "`mask_and_scale`: ... If the `_Unsigned` attribute is present treat integer arrays as unsigned." | `_Unsigned` is part of mask/scale decoding for integer variables. | Encoded in INTENT_SPEC and SPEC. |
| E7 | source pipeline | `decode_cf_variable` applies `UnsignedIntegerCoder()`, then `CFMaskCoder()`, then `CFScaleOffsetCoder()` | Fill values must be recast before masking; no later phase should repair signedness. | Encoded as proof obligation PO4. |
| E8 | source tests | Existing helper data uses `_Unsigned`: `"true"` and `"false"` for roundtrip cases. | Preserve string marker support. | Encoded in claims for string markers. |
| E9 | source tests | Existing helper data marks boolean `True` as "Bad `_Unsigned` attribute." | Boolean marker behavior was historically weak; public issue supplies new evidence for boolean `False`, and symmetry supports explicit boolean `True` in decode only. | Encoded as V2 decision, not an encode change. |
| E10 | implementation | `pydap_.py` passes `var.attributes` through `_fix_attributes` into `Variable` attrs. | The decoder should interpret the marker after backend attribute ingestion. | Encoded in compatibility audit. |
