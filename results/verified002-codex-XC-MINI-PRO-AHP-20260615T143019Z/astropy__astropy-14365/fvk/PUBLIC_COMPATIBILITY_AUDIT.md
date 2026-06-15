# Public Compatibility Audit

Status: constructed audit; no execution performed.

## Changed symbol

- `astropy.io.ascii.qdp._line_type(line, delimiter=None)`
  - Signature: unchanged.
  - Return categories: unchanged (`comment`, `command`, `data,<n>`, `new`).
  - New accepted inputs: case variants of the already-supported `READ SERR` and
    `READ TERR` command lines.
  - Compatibility status: pass.

## Public reader path

- `QDP.read(self, table)` still calls `_read_table_qdp` with the same arguments.
- `_read_table_qdp(qdp_file, names=None, table_id=None, delimiter=None)` keeps
  its signature and return behavior.
- `_get_tables_from_qdp_file(qdp_file, input_colnames=None, delimiter=None)`
  keeps its signature and continues to build `err_specs` with lowercase keys.
- Compatibility status: pass.

## Writer path

- `QDP.write(self, table)` and `_write_table_qdp` are unchanged.
- Emitted command casing remains uppercase (`READ SERR`, `READ TERR`).
- Compatibility status: pass.

## Overrides and subclass dispatch

No subclass override or virtual dispatch shape was changed. The patch does not
add new keyword arguments, alter return types, or change a producer/consumer
data structure.
