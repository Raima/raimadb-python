# cython: language_level=3

from .retcodetypes cimport RDM_RETCODE
from .types cimport RDM_ENCRYPT, RDM_ENC_TYPE
from .tfstypes cimport RDM_TFS
from .validate cimport _ValidateTfs, _ValidateEncrypt

cdef extern from "rdmencryptapi.h":
    RDM_RETCODE rdm_encryptFree(RDM_ENCRYPT enc) nogil
    RDM_RETCODE rdm_encryptGetType(RDM_ENCRYPT enc, RDM_ENC_TYPE *ptype) nogil

cdef extern from "rdmtfsapi.h":
    RDM_RETCODE rdm_tfsAllocEncrypt(RDM_TFS hTFS, const char *passcode, RDM_ENCRYPT *pEnc) nogil

cdef class RdmEncrypt(_ValidateEncrypt):
    pass
