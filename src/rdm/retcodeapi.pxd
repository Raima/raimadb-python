# cython: language_level=3

from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmretcodeapi.h":
    RDM_RETCODE rdm_retcodeGetCode(const char *retCodeName) nogil
    const char *rdm_retcodeGetDescription(RDM_RETCODE retcode) nogil
    const char *rdm_retcodeGetName(RDM_RETCODE retcode) nogil

cdef str getDescription(int code)
cdef str getName(int code)
