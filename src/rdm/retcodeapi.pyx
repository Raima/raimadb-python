# cython: language_level=3

cdef str getDescription(int code):
    c_description = rdm_retcodeGetDescription(<RDM_RETCODE> code)
    return c_description.decode('utf-8') if c_description is not None else "Unknown error"

cdef str getName(int code):
    c_name = rdm_retcodeGetName(<RDM_RETCODE> code)
    return c_name.decode('utf-8') if c_name is not None else "<UNKNOWN>"

def getDescription(int code):
    c_description = rdm_retcodeGetDescription(<RDM_RETCODE> code)
    return c_description.decode('utf-8') if c_description is not None else "Unknown error"

def getName(RDM_RETCODE code):
    c_name = rdm_retcodeGetName(<RDM_RETCODE> code)
    return c_name.decode('utf-8') if c_name is not None else "<UNKNOWN>"