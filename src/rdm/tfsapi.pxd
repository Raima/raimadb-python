# cython: language_level=3

from libc.stdint cimport uint16_t
from libc.stddef cimport size_t
from .tfstypes cimport RDM_TFS, TFS_TYPE
from .types cimport RDM_DB, RDM_ENCRYPT
from .retcodetypes cimport RDM_RETCODE
from libcpp cimport bool
from .encryptapi cimport RdmEncrypt
from .validate cimport _ValidateTfs

cdef class RdmTfs(_ValidateTfs):
    pass

cdef extern from "rdmtfsapi.h":
    RDM_RETCODE rdm_tfsAllocDatabase(RDM_TFS tfs, RDM_DB *pDb) nogil
    RDM_RETCODE rdm_tfsAllocEncrypt(RDM_TFS hTFS, const char *passcode, RDM_ENCRYPT *pEnc) nogil
    RDM_RETCODE rdm_tfsDisableListener(RDM_TFS hTFS) nogil
    RDM_RETCODE rdm_tfsDropDatabase(RDM_TFS tfs, const char *dbNameSpec) nogil
    RDM_RETCODE rdm_tfsEnableListener(RDM_TFS hTFS) nogil
    RDM_RETCODE rdm_tfsFree(RDM_TFS hTFS) nogil
    RDM_RETCODE rdm_tfsGetMemUsage(RDM_TFS tfs, size_t *curr_usage, size_t *max_usage) nogil
    RDM_RETCODE rdm_tfsGetInfo(RDM_TFS hTFS, const char *uri, const char *optString, size_t bufSizeInBytes, char *buffer, size_t *numBytesWritten) nogil
    RDM_RETCODE rdm_tfsGetEncrypt(RDM_TFS tfs, RDM_ENCRYPT *enc) nogil
    RDM_RETCODE rdm_tfsGetOption(RDM_TFS tfs, const char *keyword, char *optValue, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_tfsGetOptions(RDM_TFS tfs, char *optString, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_tfsGetVersion(RDM_TFS hTFS, uint16_t *pMajorV, uint16_t *pMinorV, TFS_TYPE *pTfsType) nogil
    RDM_RETCODE rdm_tfsKillAllRemoteConnections(RDM_TFS tfs, const char *uri) nogil
    RDM_RETCODE rdm_tfsKillRemoteConnection(RDM_TFS hTFS, const char *uri, const char *dbUserID) nogil
    RDM_RETCODE rdm_tfsPing(RDM_TFS hTFS, const char *uri) nogil
    RDM_RETCODE rdm_tfsSetOption(RDM_TFS tfs, const char *keyword, const char *strValue) nogil
    RDM_RETCODE rdm_tfsSetOptions(RDM_TFS tfs, const char *optString) nogil
    RDM_RETCODE rdm_tfsGetCapability(RDM_TFS tfs, const char *name, bool *pvalue) nogil
    RDM_RETCODE rdm_tfsInitialize(RDM_TFS tfs) nogil
    RDM_RETCODE rdm_tfsSetCertificate(RDM_TFS tfs, const char *certificate) nogil
    RDM_RETCODE rdm_tfsSetKey(RDM_TFS tfs, const char *private_key) nogil
