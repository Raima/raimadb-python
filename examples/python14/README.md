# python14 — BLOB columns

This example from the C-Core series is **not ported to the Python
interface** at this time (out of scope for the initial port). It is
straightforward to port once the BLOB read/write surface in the
Python bindings has been verified.

For the full discussion, see the C source shipped with your RaimaDB
installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core14Example/core14Example_main.c

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C example:

- Reading and writing BLOB (binary large object) column data,
  including streaming and segmented access patterns.
