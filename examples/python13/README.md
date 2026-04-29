# python13 — Nested transactions

This example from the C-Core series is **not ported to the Python
interface** for the same reason as
[python09](../python09/README.md): the C example builds on
core09Example_main.c and depends on starting transactions with an
explicit array of tables to lock. In particular,
`insert_students()` calls `rdm_dbStartUpdate(hDB, table_student,
RDM_LEN(table_student), ...)` to take a write lock on a specific
table, and `register_for_course()` starts a *nested* transaction
specifically to incrementally acquire additional read locks on
further tables. The current Python bindings expose
`db.startRead()` / `db.startUpdate()` with no parameters \(they
implicitly lock all tables, `RDM_LOCK_ALL`\), so the central
demonstration of this example \-\- nested transactions used to grow
the lock set \-\- cannot be expressed.

The Python bindings *do* support nested transactions in general.
Once `startRead`/`startUpdate` grow an optional `tables=` keyword
\(see [python09/README.md](../python09/README.md)\) this example
becomes straightforward to port.

For the full discussion, see the C source shipped with your RaimaDB
installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core13Example/core13Example_main.c

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C example:

- Nested transactions \(starting a transaction within an already
  active transaction; committing or rolling back the inner
  transaction independently of the outer one\), used here to
  acquire additional table-level locks incrementally.
