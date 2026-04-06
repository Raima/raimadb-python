# cython: language_level=3

from .validate cimport _ValidateTrans

cdef class RdmTrans(_ValidateTrans):
    pass
