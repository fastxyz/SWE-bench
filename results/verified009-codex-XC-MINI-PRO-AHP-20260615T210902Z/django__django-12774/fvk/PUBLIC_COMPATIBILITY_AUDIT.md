# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed symbol: `QuerySet.in_bulk(self, id_list=None, *, field_name='pk')`.

Signature compatibility: pass. The function signature is unchanged.

Return-shape compatibility: pass. Accepted calls still return a dictionary
mapping `getattr(obj, field_name)` to `obj`; rejected calls still raise the
same `ValueError` message.

Callsite compatibility: pass. Public callsites using the default primary key or
`unique=True` fields remain accepted. The change only expands accepted
field-name cases to include single-field total `UniqueConstraint`s.

Subclass/override compatibility: pass. No new virtual method call, keyword
argument, or override requirement was introduced.

Producer/consumer compatibility: pass. The code continues to consume
`Options.total_unique_constraints`, `Field.name`, and `Field.attname` metadata
without changing their formats.
