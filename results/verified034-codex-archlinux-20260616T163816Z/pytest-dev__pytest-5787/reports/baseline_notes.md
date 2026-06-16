# Baseline Notes

## Root cause

Pytest already builds a full `ExceptionChainRepr` for chained exceptions, and
normal local terminal reporting prints each traceback in that chain. The report
serialization path in `src/_pytest/reports.py` only serialized the top-level
`reprtraceback` and `reprcrash` attributes, however. Because
`ExceptionChainRepr.reprtraceback` and `.reprcrash` intentionally point to only
the newest exception in the chain, xdist-style serialization dropped all earlier
exceptions and their chain descriptions.

## Changed files

`repo/src/_pytest/reports.py`

The report serializer now uses shared helpers for serializing traceback entries,
tracebacks, and crash locations. When the longrepr is an `ExceptionChainRepr`,
it also writes a `chain` list containing each chain element's traceback, crash
location, and connecting description. The top-level `reprtraceback` and
`reprcrash` keys are still emitted for compatibility with existing consumers.

The deserializer now rebuilds that optional `chain` list as an
`ExceptionChainRepr`; reports without the new key still deserialize through the
previous single-exception `ReprExceptionInfo` shape. Sections continue to be
reapplied after the exception representation is reconstructed.

## Assumptions and alternatives

I assumed the serialized report format may be consumed by plugins which already
look for top-level `reprtraceback` and `reprcrash`, so the fix adds chain data
without removing those keys.

I assumed the correct behavior is to preserve pytest's existing terminal
rendering semantics exactly, including the distinction between direct causes and
implicit contexts. For that reason, the chain description string is serialized
with each chain element instead of being recomputed during deserialization.

I considered converting chained exception longreprs to plain strings during
serialization. That would preserve display text, but it would discard structured
attributes such as `reprcrash`, `reprtraceback`, and sections, which are used by
pytest and plugins. I rejected that approach.

I considered changing `_pytest._code.code.ExceptionChainRepr` itself, but the
chain representation is already correct before serialization. The loss happens
only in the report JSON conversion, so the fix is limited to `reports.py`.
