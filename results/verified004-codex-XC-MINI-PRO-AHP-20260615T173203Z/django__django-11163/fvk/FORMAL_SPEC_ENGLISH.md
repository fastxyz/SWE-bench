# Formal Spec in English

Claim `MODEL-TO-DICT-GENERAL`:

For every finite model field sequence, `model_to_dict(fields, exclude, fields_seq)`
returns a result map containing exactly the editable fields whose names are
allowed by the provided `fields` argument and not removed by `exclude`. The read
log contains exactly the names inserted into the result map.

Claim `FILTER-FIELDS-CIRCULARITY`:

Processing a field sequence from any accumulated map/read-log state is equivalent
to processing the first field according to the editability, inclusion, and
exclusion checks, then recursively processing the remaining fields.

Claim `MODEL-TO-DICT-EMPTY-FIELDS`:

For any finite field sequence and any `exclude` value,
`model_to_dict(fields=[], exclude=exclude)` returns an empty map and an empty
read log.

Frame condition:

The function signature and return type are unchanged. The only altered behavior
is the distinction between omitted `fields` and an explicitly provided empty
field list.
