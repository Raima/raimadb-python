# cython: language_level=3

from libc.stdint cimport int8_t, uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t

cdef extern from "psptypes.h":
    cdef enum RDM_COMPARE_E:
        RDM_LT = -1
        RDM_EQ = 0
        RDM_GT = 1
    
    ctypedef RDM_COMPARE_E RDM_COMPARE
