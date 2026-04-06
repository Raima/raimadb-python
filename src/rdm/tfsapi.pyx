# cython: language_level=3

from libc.stdint cimport uint16_t
from libc.stddef cimport size_t
from .tfstypes cimport RDM_TFS, TFS_TYPE
from .types cimport RDM_ENCRYPT
from .retcodetypes cimport RDM_RETCODE, sOKAY
from .exceptions_factory import factory
from .encryptapi cimport RdmEncrypt
from libcpp cimport bool
from .validate cimport _ValidateTfs
from .dbapi cimport RdmDb
from .validate cimport _token

cdef extern from "rdmrdmapi.h":
    RDM_RETCODE rdm_rdmAllocTFS(RDM_TFS *pTfs) nogil

cdef class RdmTfs(_ValidateTfs):

    def allocDatabase (self):
        cdef RdmDb db = RdmDb(self, _token)
        return db
    
    def allocEncrypt (self, str passCode):
        cdef RdmEncrypt enc = RdmEncrypt(self, passCode, _token)
        return enc
 
    def disableListener(self):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsDisableListener(self.tfs)
        return factory.handleCode(ret)

    def dropDatabase(self, str dbNameSpec):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsDropDatabase(self.tfs, dbNameSpec.encode())
        return factory.handleCode(ret)

    def enableListener(self):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsEnableListener(self.tfs)
        return factory.handleCode(ret)

    def getMemUsage(self):
        cdef size_t curr_usage, max_usage
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetMemUsage(self.tfs, &curr_usage, &max_usage)
        return factory.handleCode(ret), curr_usage, max_usage

    def getInfo(self, str uri, str optString, size_t bufSizeInBytes):
        cdef bytearray buffer = bytearray(bufSizeInBytes)
        cdef size_t numBytesWritten
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetInfo(self.tfs, uri.encode(), optString.encode(), bufSizeInBytes, <char*>buffer, &numBytesWritten)
        return factory.handleCode(ret), bytes(buffer[:numBytesWritten])

    #def getEncrypt(self):
    #    cdef RDM_ENCRYPT enc
    #    ret = rdm_tfsGetEncrypt(self.tfs, &enc)
    #    if ret != sOKAY:
    #        factory.handleCode(ret)
    #    return RdmEncrypt.from_handle(self, enc)

    def getOption(self, str keyword, size_t bufSizeInBytes):
        cdef bytearray optValue = bytearray(bufSizeInBytes)
        cdef size_t bytesOut
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetOption(self.tfs, keyword.encode(), <char*>optValue, bufSizeInBytes, &bytesOut)
        return factory.handleCode(ret), bytes(optValue[:bytesOut])

    def getOptions(self, size_t bufSizeInBytes):
        cdef bytearray optString = bytearray(bufSizeInBytes)
        cdef size_t bytesOut
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetOptions(self.tfs, <char*>optString, bufSizeInBytes, &bytesOut)
        return factory.handleCode(ret), bytes(optString[:bytesOut])

    def getVersion(self):
        cdef uint16_t majorV, minorV
        cdef TFS_TYPE tfsType
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetVersion(self.tfs, &majorV, &minorV, &tfsType)
        return factory.handleCode(ret), majorV, minorV, tfsType

    def killAllRemoteConnections(self, str uri):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsKillAllRemoteConnections(self.tfs, uri.encode())
        return factory.handleCode(ret)

    def killRemoteConnection(self, str uri, str dbUserID):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsKillRemoteConnection(self.tfs, uri.encode(), dbUserID.encode())
        return factory.handleCode(ret)

    def ping(self, str uri):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsPing(self.tfs, uri.encode())
        return factory.handleCode(ret)

    def setOption(self, str keyword, str strValue):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsSetOption(self.tfs, keyword.encode(), strValue.encode())
        return factory.handleCode(ret)

    def setOptions(self, str optString):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsSetOptions(self.tfs, optString.encode())
        return factory.handleCode(ret)

    def getCapability(self, str name):
        cdef bool pvalue
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsGetCapability(self.tfs, name.encode(), &pvalue)
        return factory.handleCode(ret), pvalue

    def initialize(self):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsInitialize(self.tfs)
        return factory.handleCode(ret)

    def setCertificate(self, str certificate):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsSetCertificate(self.tfs, certificate.encode())
        return factory.handleCode(ret)

    def setKey(self, str private_key):
        ret = super()._validate ()
        if ret == sOKAY:
            ret = rdm_tfsSetKey(self.tfs, private_key.encode())
        return factory.handleCode(ret)
