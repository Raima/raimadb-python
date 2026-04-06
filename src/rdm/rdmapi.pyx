# cython: language_level=3

from libc.stddef cimport size_t
from libc.stdlib cimport malloc, free
from .tfstypes cimport RDM_TFS
from .types cimport RDM_CURSOR
from .retcodetypes cimport RDM_RETCODE, sOKAY
from .exceptions_factory import factory
from .tfsapi cimport RdmTfs
from .validate cimport _token
#from cursorapi cimport RdmCursor

cdef extern from "rdmrdmapi.h":
    RDM_RETCODE rdm_rdmAllocTFS(RDM_TFS *phTFS) nogil
#    RDM_RETCODE rdm_rdmGetAfterLast(RDM_CURSOR *pCursor) nogil
#    RDM_RETCODE rdm_rdmGetBeforeFirst(RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_rdmGetVersion(const char *fmt, char *buf, size_t bytesIn) nogil

def allocTfs() -> RdmTfs:
    """Allocate an RdmTfs instance with an RDM_TFS handle."""
    cdef RdmTfs tfs = RdmTfs(_token)
    return tfs

#def getAfterLast():
#    """Get the special AfterLast cursor."""
#    cdef RDM_CURSOR c_cursor
#    cdef RDM_RETCODE ret = rdm_rdmGetAfterLast(&c_cursor)
#    factory.handleCode(ret)
#    cdef RdmCursor cursor = RdmCursor()
#    cursor.c_cursor = c_cursor
#    cursor.is_special = True
#    return cursor

#def getBeforeFirst():
#    """Get the special BeforeFirst cursor."""
#    cdef RDM_CURSOR c_cursor
#    cdef RDM_RETCODE ret = rdm_rdmGetBeforeFirst(&c_cursor)
#    factory.handleCode(ret)
#    cdef RdmCursor cursor = RdmCursor()
#    cursor.c_cursor = c_cursor
#    cursor.is_special = True
#    return cursor

def getVersion(fmt=None) -> str:
    """Get the RaimaDB version string with an optional format."""
    if fmt is None:
        fmt = b"%V"
    else:
        fmt = fmt.encode('utf-8')
    cdef size_t buf_size = 1024
    cdef char* buf = <char*>malloc(buf_size)
    if not buf:
        raise MemoryError()
    cdef RDM_RETCODE ret
    try:
        ret = rdm_rdmGetVersion(fmt, buf, buf_size)
        factory.handleCode(ret)
        return buf.decode('utf-8')
    finally:
        free(buf)

