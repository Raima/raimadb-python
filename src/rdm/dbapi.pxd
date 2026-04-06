# cython: language_level=3

from .types cimport RDM_DB, RDM_RETCODE, RDM_OPEN_MODE
from .tfstypes cimport RDM_TFS
from .validate cimport _ValidateDb

cdef class RdmDb(_ValidateDb):
    cdef public dict _tables
    cdef public dict _keys
    cdef public dict _references
    cdef public dict _userDefinedTypes
