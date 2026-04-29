# python09 — Explicit table locking

This example from the C-Core series is **not ported to the Python
interface** because the current Python bindings expose
`db.startRead()` and `db.startUpdate()` with no parameters: they
implicitly lock all tables (`RDM_LOCK_ALL`) and there is no way to
pass an array of table ids for finer-grained locking.

For the full discussion, see the C source shipped with your RaimaDB
installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core09Example/core09Example_main.c

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C example:

- Locking specific tables when starting a read or update transaction

The C example demonstrates passing explicit table-id arrays to
`rdm_dbStartRead()` / `rdm_dbStartUpdate()` to reduce contention with
other transactions. A future revision of the Python bindings could
add an optional `tables=` keyword to `startRead`/`startUpdate` to
expose this; the rest of the example flow would mirror python02 with
that single substitution.
