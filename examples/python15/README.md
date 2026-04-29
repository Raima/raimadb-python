# python15 — R-tree spatial indexing

This example from the C-Core series is **not ported to the Python
interface** at this time (out of scope for the initial port). A
port depends on verifying that the Python bindings expose
`getRowsByKeyInRtreeKeyRange` and the associated R-tree key types.

For the full discussion, see the C source shipped with your RaimaDB
installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core15Example/core15Example_main.c

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C example:

- R-tree (multi-dimensional / spatial) indexes and range queries
  over them.
