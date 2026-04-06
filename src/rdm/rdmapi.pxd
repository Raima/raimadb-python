# cython: language_level=3

from libc.stddef cimport size_t
from .tfstypes cimport RDM_TFS
from .types cimport RDM_CURSOR
from .retcodetypes cimport RDM_RETCODE
# from tfsapi cimport RdmTfs
# TBD from cursorapi cimport RdmCursor  # Import RdmCursor from cursorapi

cdef extern from "rdmrdmapi.h":
    RDM_RETCODE rdm_rdmAllocTFS(RDM_TFS *phTFS) nogil
#    RDM_RETCODE rdm_rdmGetAfterLast(RDM_CURSOR *pCursor) nogil
#    RDM_RETCODE rdm_rdmGetBeforeFirst(RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_rdmGetVersion(const char *fmt, char *buf, size_t bytesIn) nogil
