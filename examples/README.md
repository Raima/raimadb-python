# RaimaDB Python C-Core Examples

This directory contains Python ports of the *Getting Started* C-Core
example series that ships with RaimaDB. The originals live with
your RaimaDB installation under

    <RDM_INSTALL>/share/RDM/GettingStarted/c-core/

where `<RDM_INSTALL>` is the install root for your RaimaDB build. On
a typical Linux install that is e.g.
`/opt/Raima/rdm_core-<version>/share/RDM/GettingStarted/c-core/`
(the exact version directory varies); on other platforms the layout
is the same but the prefix differs (the installer's docs spell out
the location). Whenever a Python example or a skipped-example
README cross-references a C source file by bare filename
(e.g. `core03Example_main.c`) you can find it under the
corresponding `coreNNExample/` subdirectory of that path.

Each ported example lives in its own `pythonNN/` directory as a
self-contained `pythonNNExample.py` script. Run any example
directly with `python examples/pythonNN/pythonNNExample.py` from
the repository root.

## Status

| #  | Topic                                            | Python port           |
|----|--------------------------------------------------|-----------------------|
| 01 | TFS handle, db handle, transaction, cursor       | python01 (ported)     |
| 02 | Primary key, cursor navigation                   | python02 (ported)     |
| 03 | Row IDs and foreign key columns                  | python03 (ported)     |
| 04 | Network model — many-to-one navigation           | python04 (ported)     |
| 05 | Network model — one-to-many via set cursor       | python05 (ported)     |
| 06 | Many-to-many                                     | python06 (ported)     |
| 07 | In-memory storage modes                          | python07 (ported)     |
| 08 | Multiple database handles + union database       | python08 (ported)     |
| 09 | Explicit table locking                           | skipped — see [python09/README.md](python09/README.md) |
| 10 | Snapshot transactions                            | skipped — see [python10/README.md](python10/README.md) |
| 11 | Encrypted database                               | python11 (ported)     |
| 12 | C++ template helpers                             | skipped — see [python12/README.md](python12/README.md) |
| 13 | Nested transactions                              | skipped — see [python13/README.md](python13/README.md) |
| 14 | BLOB columns                                     | skipped — see [python14/README.md](python14/README.md) |
| 15 | R-tree spatial indexing                          | skipped — see [python15/README.md](python15/README.md) |
| 16 | TFS modes — embed/server/client/hybrid           | python16 (ported)     |
| 17 | TFS with SSL                                     | python17 (ported)     |
| 18 | C++ inner join by foreign reference              | skipped — see [python18/README.md](python18/README.md) |
| 19 | C++ inner join by unique key                     | skipped — see [python19/README.md](python19/README.md) |
| 20 | Continuous reader/writer (replication building block) | python20 (ported) |

A skipped example means the C-Core idea either has no clean Python
analogue at the current state of the bindings, is C++-template-only,
is blocked on a known binding issue, or is out of scope for this
initial port. Each `pythonNN/README.md` for a skipped example
records the reason and points back to the C/C++ source.

## Reading order

The ported examples build on each other and are best read in
numerical order, especially python01 → python02 → python03 →
python04 → python05 → python06.
