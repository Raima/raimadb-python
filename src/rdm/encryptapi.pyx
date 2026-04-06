# cython: language_level=3

from .exceptions_factory import factory
from .retcodetypes import Status
from .retcodetypes cimport RDM_RETCODE, sOKAY, eINVFCNSEQ
from .types cimport RDM_ENCRYPT, RDM_ENC_TYPE
from .validate cimport _ValidateTfs, _ValidateEncrypt

from typing import Tuple

cdef class RdmEncrypt(_ValidateEncrypt):
    def getType(self) -> tuple [RDM_ENC_TYPE, Status] :
        """Get the encryption type of the context.

        Returns:
            tuple: A tuple containing the encryption type (RDM_ENC_TYPE) and the status code.

        Raises:
            ErrorINVFCNSEQ: If the encryption context is invalid or freed.
            Exception: If retrieving the type fails, an exception is raised with the error code.
        """
        cdef RDM_RETCODE rc = super()._validate()
        cdef RDM_ENC_TYPE ptype
        if rc == sOKAY:
            rc = rdm_encryptGetType(self.enc, &ptype)
        return ptype, factory.handleCode(rc)