# raimadb-python

Python interface for [RaimaDB](https://raima.com/) implemented in [Cython](https://cython.org/).

## Prerequisites

- **Python 3.9+**
- **RaimaDB 16.1** installed (any edition: core, pro, or enterprise)
- **C++ compiler** (GCC, Clang, or MSVC)
- **Cython 3.0+** (installed automatically during build)

## Clone

```bash
git clone https://github.com/Raima/raimadb-python.git
cd raimadb-python
```

## RDM Installation

The build automatically detects RaimaDB installations in the
platform-specific default location:

| Platform      | Search path   |
|---------------|---------------|
| Linux / macOS | `/opt/Raima/` |
| Windows       | `C:/Raima/`   |

It looks for directories matching `rdm_<edition>-<version>` and picks the
newest version with the highest-ranked edition
(core > pro > enterprise).

No environment variables need to be set.

## Build and Install

### Standard install

```bash
pip install .
```

### Editable install (for development)

An editable install builds the extensions in-place so that changes to `.py`
files take effect immediately. Cython `.pyx` files still require a rebuild.

```bash
pip install -e .
```

> **Tip:** Use a virtual environment to keep your system Python clean:
>
> ```bash
> python -m venv .venv
> source .venv/bin/activate
> pip install -e .
> ```

## Code Generation

The error-code and exception modules (`retcodetypes`, `exceptions`) are
auto-generated from `errordefns.txt` (shipped with the RDM installation under
`share/RDM/`) during each build.

To run the code generator manually (e.g. to inspect output):

```bash
python codegen/genErrors_python.py [path/to/errordefns.txt]
```

## Running the Example

The `examples/python01` directory contains an introductory example that
creates a database, inserts a row, and reads it back.

```bash
python examples/python01/python01Example_main.py
```

Expected output:

```
The row read from the database is: Hello World!
```

Clean up database files afterwards if desired:

```bash
rm -rf python01.rdm tfserver.lock
```

## Running the Tests

Tests use the `unittest` framework and follow the `test_*.py` naming
convention, so they work with both `unittest` and `pytest`.

### With pytest

```bash
pip install pytest     # if not already installed
pytest tests/
```

### With unittest

```bash
python -m unittest discover -s tests
```

### Running a single test

```bash
pytest tests/test_basicOperations.py
```

## Project Structure

```
raimadb-python/
├── pyproject.toml          # PEP 517/518 build configuration
├── setup.py                # Extension module definitions
├── src/
│   └── rdm/                # The raimadb Python package
│       ├── __init__.py
│       ├── *.pyx / *.pxd   # Cython source modules
│       ├── bcd_convert.cpp  # C++ helper for BCD types
│       └── rdm_internals.h  # Compatibility header
├── codegen/                # Error-code generation scripts
│   ├── genErrors_common.py
│   └── genErrors_python.py
├── tests/                  # Unit tests
│   └── test_*.py
└── examples/               # Example programs
    └── python01/
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for
details.
