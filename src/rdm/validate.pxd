# cython: language_level=3

import weakref

from .tfstypes cimport RDM_TFS
from .types cimport RDM_DB, RDM_ENCRYPT, RDM_TRANS, RDM_CURSOR

cdef object _token


cdef class _ValidateTfs:
    cdef object __weakref__
    cdef RDM_TFS tfs

cdef class _ValidateEncrypt:
    cdef RDM_ENCRYPT enc
    cdef object tfs

cdef class _ValidateDb:
    cdef object __weakref__
    cdef RDM_DB db
    cdef object tfs
    cdef object lastTrans
    cdef int closeCount

cdef class _ValidateTrans:
    cdef object __weakref__
    cdef RDM_TRANS trans
    cdef object db
    cdef object prevTrans

cdef class _ValidateCursor:
    cdef RDM_CURSOR cursor
    cdef object db
    cdef int closeNumber

