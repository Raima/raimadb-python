# cython: language_level=3

from .validate cimport _ValidateCursor

cdef extern from "rdmtypes.h":
    ctypedef enum RDM_CURSOR_COMPARE:
        RDM_LT
        RDM_EQ
        RDM_GT
    cdef RDM_CURSOR_COMPARE CURSOR_BEFORE = RDM_LT
    cdef RDM_CURSOR_COMPARE CURSOR_EQUAL = RDM_EQ
    cdef RDM_CURSOR_COMPARE CURSOR_AFTER = RDM_GT

cdef class RdmCursor(_ValidateCursor):
    cpdef _isAtRow (self) 
    cdef bint at_row
    cdef RDM_CURSOR_COMPARE _get_comparison(self, RdmCursor other) except *
