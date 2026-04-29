# python19 — C++ inner join by unique key

This example from the C-Core series is **not ported to the Python
interface** because it relies on C++ template helpers for joining
rows by a unique key. As with python18, the Python equivalent is
to walk the relationship explicitly with `cursor.moveToKey(...)`
or `cursor.moveToRowId(...)` after retrieving the join column.

For the full discussion, see the C++ source shipped with your
RaimaDB installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core19Example/core19Example_main.cpp

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C++ example:

- Inner join over a unique key using the C++ template helpers in
  `<rdmcpp.h>`.
