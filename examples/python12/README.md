# python12 — C++ template helpers

This example from the C-Core series is **not ported to the Python
interface** because it demonstrates C++-specific template helpers
that wrap the C API. The Python bindings already hide buffer
sizes, struct layouts, and explicit type wrapping, so there is no
direct analogue to port.

For the full discussion, see the C++ source shipped with your
RaimaDB installation:

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/core12Example/core12Example_main.cpp

(The top-level [examples/README.md](../README.md) explains where
`<RDM_INSTALL>` lives on a typical platform.)

Concept introduced by the C++ example:

- Using the C++ template helpers in `<rdmcpp.h>` to reduce
  boilerplate when accessing rows and cursors from C++ code.

The pythonic equivalents \(attribute access on dynamically generated
row classes, automatic buffer management\) are demonstrated
throughout the rest of the ported examples \(python01 onwards\).
