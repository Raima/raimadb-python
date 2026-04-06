# codegen/genErrors_python.py

import os
import re
import sys

# Load common
sys.path.insert(0, os.path.dirname(__file__))
from genErrors_common import parse_statuses_and_errors, transform_name

# Output paths: write into src/rdm/ relative to this script's parent directory
project_root = os.path.dirname(os.path.dirname(__file__))
src_rdm = os.path.join(project_root, 'src', 'rdm')
retcodetypes_pdx_dst = os.path.join(src_rdm, 'retcodetypes.pxd')
retcodetypes_pyx_dst = os.path.join(src_rdm, 'retcodetypes.pyx')
exceptions_pdx_dst = os.path.join(src_rdm, 'exceptions.pxd')
exceptions_pyx_dst = os.path.join(src_rdm, 'exceptions.pyx')

if len(sys.argv) < 2:
    print("Usage: genErrors_python.py <path/to/errordefns.txt>", file=sys.stderr)
    sys.exit(1)
errors, maxgrouplen, maxcodelen = parse_statuses_and_errors(sys.argv[1])

# Collect error codes (negative numbers) and status codes (positive)
error_codes = []
status_codes = []
for group in errors:
    for code in group['codes']:
        # Python-specific name transformations
        raw_name = code['raw_name']
        uc_name = transform_name(raw_name)
        name = re.sub(r'_([A-Z])', r'\1', raw_name)
        code['name'] = name
        code['uc_name'] = uc_name
        if code['num'] < 0:
            error_codes.append(code)
        else:
            status_codes.append(code)

# Function to generate retcodetypes.pxd
def generate_retcodetypes_pxd(dst, errors):
    with open(dst, 'w') as pxd:
        # Write Cython preamble
        pxd.write("# cython: language_level=3\n\n")
        pxd.write("from libc.stdint cimport int32_t\n\n")
        pxd.write("cdef extern from \"rdmretcodetypes.h\":\n")
        pxd.write("    ctypedef enum RDM_RETCODE_E:\n")

        # Identify the last code for comma handling
        last_group = errors[-1]
        last_codes = last_group['codes']
        last_code = last_codes[-1]

        # Generate enum values
        for error in errors:
            pxd.write("        # " + error['name'] + " codes:\n")
            for info in error['codes']:
                comma = "" if (error == last_group and info == last_code) else ","
                pxd.write("        " + info['uc_name'] + " = " + str(info['num']) + comma + "  # " + info['desc'] + "\n")

        # Complete the typedef and add inline functions
        pxd.write("    ctypedef RDM_RETCODE_E RDM_RETCODE\n\n")
        pxd.write("cdef inline int32_t RDM_IS_ERROR(RDM_RETCODE c):\n")
        pxd.write("    return 1 if c < 0 else 0\n\n")
        pxd.write("cdef inline int32_t RDM_IS_INFO(RDM_RETCODE c):\n")
        pxd.write("    return 1 if c >= 0 else 0\n\n")
        pxd.write("cdef inline int32_t RDM_IS_NOTIMPLEMENTED(RDM_RETCODE c):\n")
        pxd.write("    return 1 if c > eNOTIMPLEMENTED_MIN and c < eNOTIMPLEMENTED_MAX else 0\n")

# Function to generate retcodetypes.pyx
def generate_retcodetypes_pyx(dst, status_codes):
    with open(dst, 'w') as pyx:
        # Write Cython preamble
        pyx.write("# cython: language_level=3\n\n")
        pyx.write("from .retcodeapi cimport getDescription, getName\n\n")
        pyx.write("from enum import IntEnum\n")
        pyx.write("from libc.stdint cimport int32_t\n\n")
        pyx.write("class Status(IntEnum):\n")

        # Generate enum values
        for status in status_codes:
            raw_name = status['raw_name']
            raw_name = raw_name[1:] if raw_name.startswith('s') else raw_name
            pyx.write("    " + raw_name + " = " + str(status['num']) + "\n")

        pyx.write("    @property\n")
        pyx.write("    def name(self):\n")
        pyx.write("        return getName(self.value)\n")
        pyx.write("    @property\n")
        pyx.write("    def description(self):\n")
        pyx.write("        return getDescription(self.value)\n")
        pyx.write("    def __str__(self):\n")
        pyx.write("        return f\"Status {self.name}({self.value}): {self.description}\"\n")
        pyx.write("Status.__doc__ = \"Status codes enumeration.\\n\\n\" + \"\\n\". \\\n")
        pyx.write("    join(f\"{member._name_} = {member.value} (C/C++: {member.name}) - {member.description}\" \\\n")
        pyx.write("        for member in Status)\n")

# Function to generate exceptions.pxd
def generate_exceptions_pxd(dst):
    with open(dst, 'w') as exc_pxd:
        exc_pxd.write("# This file is machine-generated. Do not edit.\n\n")
        exc_pxd.write("cdef class RDMError(Exception):\n")
        exc_pxd.write("    pass\n\n")
        exc_pxd.write("cdef public dict exception_class_map\n")

# Function to generate exceptions.pyx
def generate_exceptions_pyx(dst, error_codes):
    with open(dst, 'w') as exc_pyx:
        exc_pyx.write("# This file is machine-generated. Do not edit.\n\n")
        exc_pyx.write("from .retcodeapi cimport getDescription, getName\n\n")
        exc_pyx.write("cdef class RDMError:\n")
        exc_pyx.write("    pass\n\n")
        exc_pyx.write("import sys\n")
        exc_pyx.write("_current_module = sys.modules[__name__]\n")
        exc_pyx.write("class_data = [\n")
        for code in error_codes:
            name = code['name']
            errorName = re.sub(r'^e', 'Error', name)
            num = code['num']
            exc_pyx.write(f"  (\"{errorName}\", {num}),\n")
        exc_pyx.write("]\n")

        exc_pyx.write("for name, code in class_data:\n")
        exc_pyx.write("    cName = getName(code)\n")
        exc_pyx.write("    description = getDescription(code)\n")
        exc_pyx.write("    docstring = f\"{name}({code}) (C/C++: {cName}) - {description}\"\n")
        exc_pyx.write("    str = f\"{name}: {description}\"\n")
        exc_pyx.write("    cls_dict = {\n")
        exc_pyx.write("        \"code\": code,\n")
        exc_pyx.write("        \"__doc__\": docstring,\n")
        exc_pyx.write("        \"__str__\": lambda self, _str=str: _str\n")
        exc_pyx.write("    }\n")
        exc_pyx.write("    new_cls = type(name, (RDMError,), cls_dict)\n")
        exc_pyx.write("    setattr(_current_module, name, new_cls)\n")

        exc_pyx.write("exception_class_map = {cls.code: cls for cls in RDMError.__subclasses__() if hasattr(cls, 'code')}\n")

# Call the generation functions
generate_retcodetypes_pxd(retcodetypes_pdx_dst, errors)
generate_retcodetypes_pyx(retcodetypes_pyx_dst, status_codes)
generate_exceptions_pxd(exceptions_pdx_dst)
generate_exceptions_pyx(exceptions_pyx_dst, error_codes)
