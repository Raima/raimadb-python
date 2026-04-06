# cython: language_level=3

cdef extern from "rdmtfstypes.h":
    ctypedef struct RDM_TFS_S
    ctypedef RDM_TFS_S* RDM_TFS
    ctypedef const RDM_TFS_S* RDM_TFS_C

    ctypedef enum TFS_TYPE:
        TFS_TYPE_DEFAULT,
        TFS_TYPE_EMBED,
        TFS_TYPE_CLIENT,
        TFS_TYPE_HYBRID,
        TFS_TYPE_RDM,
        TFS_TYPE_LOCAL