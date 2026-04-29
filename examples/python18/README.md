# python18 — C++ inner join by foreign reference

This example from the C-Core series is **not ported to the Python
interface** because it relies on C++ template helpers for joining
rows over a foreign reference. The Python equivalent is the manual
member/owner walk demonstrated in python05Example and
python06Example using `cursor.getMemberRows(reference)` and
`cursor.getOwnerRow(reference)`.

For the full discussion, see the C++ source shipped with your
RaimaDB installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core18Example/core18Example_main.cpp

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C++ example:

- Inner join across a foreign reference using the C++ template
  helpers in `<rdmcpp.h>`.
