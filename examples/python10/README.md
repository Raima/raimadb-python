# python10 — Snapshot transactions

This example from the C-Core series is **not ported to the Python
interface** because the current Python bindings have a known issue
with snapshot transactions: cursor navigation after
`db.startSnapshot()` raises `ErrorNotLocked`.

For the full discussion, see the C source shipped with your RaimaDB
installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core10Example/core10Example_main.c

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C example:

- Snapshot transactions (read a consistent point-in-time view without
  blocking writers)

Once the binding bug is fixed this example becomes trivial to port:
it is structurally identical to python02 except `startRead()` is
replaced by `startSnapshot()`.
