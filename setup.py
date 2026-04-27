"""Build script for the raimadb Python package.

Auto-detects the RDM installation and builds all Cython extension modules.
The error-code modules (retcodetypes, exceptions) are generated from
errordefns.txt (shipped with the RDM installation) before Cython compilation.

Search paths:
  Linux / macOS : /opt/Raima/
  Windows       : C:/Raima/
"""

import glob
import os
import platform
import re
import subprocess
import sys
from setuptools import setup, Extension
from setuptools.command.build_ext import build_ext as _build_ext


# ---------------------------------------------------------------------------
# RDM installation auto-detection
# ---------------------------------------------------------------------------
def _find_rdm_installation():
    """Search for the best RDM installation.

    Linux / macOS:
        Looks for symlinks /opt/Raima/rdm_<edition>-<major>.<minor> that
        point to versioned directories.  Only entries with exactly two
        version components (e.g. rdm_pro-16.1) are considered.

    Windows:
        Looks for C:/Raima/rdm_<edition>-<major>.<minor>.<patch>.<build>.
        Symlinks are not used so the full version is in the directory name.

    Editions are ranked: core, pro > enterprise.
    When multiple installations share the same version the highest-ranked
    edition wins; otherwise the newest version is selected.
    """
    if sys.platform == "win32":
        base = "C:/Raima"
        version_re = r"rdm_(\w+)-(\d+(?:\.\d+)+)$"
    else:
        base = "/opt/Raima"
        # On Unix the symlink has only major.minor
        version_re = r"rdm_(\w+)-(\d+\.\d+)$"

    edition_rank = {"core": 3, "pro": 2, "enterprise": 1}
    pattern = os.path.join(base, "rdm_*")

    candidates = []
    for path in sorted(glob.glob(pattern)):
        name = os.path.basename(path)
        m = re.match(version_re, name)
        if m and os.path.isdir(os.path.join(path, "include")):
            edition = m.group(1)
            version = tuple(int(x) for x in m.group(2).split("."))
            rank = edition_rank.get(edition, 0)
            candidates.append((version, rank, path))

    if not candidates:
        return None

    # Highest version first, then highest edition rank
    candidates.sort(key=lambda c: (c[0], c[1]), reverse=True)
    return candidates[0][2]


project_root = os.path.dirname(os.path.abspath(__file__))
rdm_install = _find_rdm_installation()

if rdm_install is None:
    search_dir = "C:/Raima" if sys.platform == "win32" else "/opt/Raima"
    print(
        f"ERROR: No RDM installation found under {search_dir}/.\n"
        "Install RaimaDB from https://raima.com/ and ensure the directory\n"
        "contains an 'include' subdirectory.",
        file=sys.stderr,
    )
    sys.exit(1)

rdm_include = os.path.join(rdm_install, "include")
rdm_lib = os.path.join(rdm_install, "lib")
src_rdm = os.path.join(project_root, "src", "rdm")

common_include_dirs = [rdm_include, src_rdm]
common_library_dirs = [rdm_lib]

# runtime_library_dirs embeds an RPATH on Linux/macOS so the loader finds
# the RDM shared libraries at runtime.  On Windows this is not used (DLLs
# must be on PATH or next to the executable).
common_runtime_dirs = [] if sys.platform == "win32" else [rdm_lib]


# ---------------------------------------------------------------------------
# Code generation step — produces retcodetypes.pxd/.pyx and exceptions.pxd/.pyx
# ---------------------------------------------------------------------------
def _run_codegen():
    """Run codegen/genErrors_python.py to (re-)generate error-code modules."""
    script = os.path.join(project_root, "codegen", "genErrors_python.py")
    errsource = os.path.join(rdm_install, "share", "RDM", "errordefns.txt")
    subprocess.check_call([sys.executable, script, errsource])


# ---------------------------------------------------------------------------
# Custom build_ext that runs codegen before cythonizing
# ---------------------------------------------------------------------------
class build_ext(_build_ext):
    def run(self):
        _run_codegen()
        # Defer the heavy Cython import + cythonize to build time only
        from Cython.Build import cythonize

        self.distribution.ext_modules = cythonize(
            self.distribution.ext_modules,
            compiler_directives={"language_level": "3"},
            include_path=[os.path.join(project_root, "src"), rdm_include],
        )
        super().run()


# ---------------------------------------------------------------------------
# Module definitions: (name, extra_sources, libraries)
# ---------------------------------------------------------------------------
modules = [
    ("rdm.retcodeapi",        [],                         ["rdmrdm"]),
    ("rdm.retcodetypes",      [],                         []),
    ("rdm.exceptions",        [],                         ["rdmrdm"]),
    ("rdm.exceptions_factory",[],                         ["rdmrdm"]),
    ("rdm.validate",          [],                         ["rdmrdm", "rdmenc"]),
    ("rdm.psptypes",          [],                         []),
    ("rdm.tfstypes",          [],                         ["rdmrdm"]),
    ("rdm.types",             [],                         ["rdmrdm"]),
    ("rdm.encryptapi",        [],                         ["rdmenc"]),
    ("rdm.cursorapi",         [],                         ["rdmrdm"]),
    ("rdm.transapi",          [],                         ["rdmrdm"]),
    ("rdm.dbapi",             ["src/rdm/bcd_convert.cpp"], ["rdmrdm"]),
    ("rdm.tfsapi",            [],                         ["rdmrdm", "rdmtfs_rdm"]),
    ("rdm.rdmapi",            [],                         ["rdmrdm"]),
]

ext_modules = []
for name, extra_sources, libraries in modules:
    pyx_file = os.path.join("src", name.replace(".", "/") + ".pyx")
    ext_modules.append(
        Extension(
            name=name,
            sources=[pyx_file] + extra_sources,
            include_dirs=common_include_dirs,
            library_dirs=common_library_dirs,
            runtime_library_dirs=common_runtime_dirs,
            libraries=libraries,
            language="c++",
        )
    )

setup(
    ext_modules=ext_modules,
    cmdclass={"build_ext": build_ext},
)
