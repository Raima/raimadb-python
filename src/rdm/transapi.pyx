# cython: language_level=3

from .types cimport RDM_TRANS, RDM_RETCODE
from .exceptions_factory import factory
from .retcodetypes cimport RDM_RETCODE, sOKAY
from .validate cimport _ValidateTrans

cdef extern from "rdmtransapi.h":
    RDM_RETCODE rdm_transFree(RDM_TRANS trans) nogil
    RDM_RETCODE rdm_transEnd(RDM_TRANS trans) nogil
    RDM_RETCODE rdm_transEndRollback(RDM_TRANS trans) nogil
    RDM_RETCODE rdm_transRollback(RDM_TRANS trans) nogil

cdef class RdmTrans(_ValidateTrans):
    def end(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_transEnd(self.trans)
            self.trans = NULL
            db = self.db()
            db.end(self, True)
        return factory.handleCode(rc)

    def endRollback(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_transEndRollback(self.trans)
            self.trans = NULL
            db = self.db()
            db.end(self, True)
        return factory.handleCode(rc)

    def rollback(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_transRollback(self.trans)
            self.trans = NULL
            db = self.db()
            db.end(self, False)
        return factory.handleCode(rc)
