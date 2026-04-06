# cython: language_level=3

import weakref

from libcpp cimport bool
from libc.stddef cimport size_t
from libc.stdlib cimport malloc, free
from .tfstypes cimport RDM_TFS
from .types cimport RDM_CURSOR, RDM_ENCRYPT, RDM_TABLE_ID, RDM_LOCK_ALL
from .retcodetypes cimport RDM_RETCODE, sOKAY, eINVFCNSEQ
from .exceptions_factory import factory

cdef object _token = object()

cdef extern from "rdmrdmapi.h":
    RDM_RETCODE rdm_rdmAllocTFS(RDM_TFS *pTfs) nogil
cdef extern from "rdmtfsapi.h":
    RDM_RETCODE rdm_tfsFree(RDM_TFS tfs) nogil
    RDM_RETCODE rdm_tfsAllocDatabase(RDM_TFS tfs, RDM_DB *pDb) nogil
    RDM_RETCODE rdm_tfsAllocEncrypt(RDM_TFS tfs, const char *passCode, RDM_ENCRYPT *pEnc) nogil
cdef extern from "rdmencryptapi.h":
    RDM_RETCODE rdm_encryptFree(RDM_ENCRYPT enc) nogil
cdef extern from "rdmdbapi.h":
    RDM_RETCODE rdm_dbFreeRollback(RDM_DB db) nogil
    RDM_RETCODE rdm_dbAllocCursor (RDM_DB db, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbStartUpdate (RDM_DB db, const RDM_TABLE_ID *, int, const RDM_TABLE_ID *, int, RDM_TRANS *pTrans) nogil
    RDM_RETCODE rdm_dbStartRead (RDM_DB db, void *, int, RDM_TRANS *pTrans) nogil
    RDM_RETCODE rdm_dbStartSnapshoot (RDM_DB db, void *, int, RDM_TRANS *pTrans) nogil
cdef extern from "rdmcursorapi.h":
    RDM_RETCODE rdm_cursorFree(RDM_CURSOR cursor) nogil
cdef extern from "rdmtransapi.h":
    RDM_RETCODE rdm_transFree(RDM_TRANS trans) nogil

cdef class _ValidateTfs:
    def __init__(self, token):
        if token is not _token:
            raise TypeError("This class cannot be instantiated directly. Please use rdm.rdmapi.allocTfs() instead")
        cdef RDM_RETCODE rc = rdm_rdmAllocTFS(&self.tfs)
        factory.handleCode(rc)

    def __dealloc__(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rdm_tfsFree (self.tfs)

    def free(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_tfsFree (self.tfs)
            self.tfs = NULL
        return factory.handleCode(rc)

    def _validate(self):
        cdef RDM_RETCODE rc = sOKAY
        if self.tfs == NULL:
            rc = eINVFCNSEQ
        return rc

cdef class _ValidateEncrypt:
    def __init__(self, _ValidateTfs tfs, str passCode, token):
        if token is not _token:
            raise TypeError("This class cannot be instantiated directly. Please use rdm.tfsapi.RdmTfs.allocEncrypt() instead")
        rc = tfs._validate()
        if rc == sOKAY:
            # Convert Passcode to bytes
            c_passCode = passCode.encode('utf-8')
            self.tfs = weakref.ref(tfs)
            rc = rdm_tfsAllocEncrypt(tfs.tfs, c_passCode, &self.enc)
        factory.handleCode(rc)

    def __dealloc__(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rdm_encryptFree (self.enc)

    def free(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_encryptFree (self.enc)
            self.enc = NULL
        return factory.handleCode(rc)

    def _validate(self):
        cdef RDM_RETCODE rc
        if self.tfs == None:
            rc = eINVFCNSEQ
        else:
            tfs_obj = self.tfs()
            if tfs_obj is None:
                rc = eINVFCNSEQ
            else:
                if self.enc == NULL:
                    rc = eINVFCNSEQ
                else:
                    rc = (<_ValidateTfs>tfs_obj)._validate()
        return rc

cdef class _ValidateDb:
    def __cinit__(self, _ValidateTfs tfs, token):
        if token is not _token:
            raise TypeError("This class cannot be instantiated directly. Please use rdm.tfsapi.RdmTfs.allocDatabase() instead")
        cdef RDM_RETCODE rc = tfs._validate()
        if rc == sOKAY:
            self.tfs = weakref.ref(tfs)
            self.closeCount = 0
            rc = rdm_tfsAllocDatabase(tfs.tfs, &self.db)
        factory.handleCode(rc)

    def __dealloc__(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rdm_dbFreeRollback (self.db)

    def end(self, _ValidateTrans target, bool inclusive):
        cdef _ValidateTrans new_last
        if inclusive:
            if target.prevTrans is not None:
                new_last = target.prevTrans()
            else:
                new_last = None
        else:
            new_last = target
        cdef _ValidateTrans current
        if self.lastTrans is not None:
            current = self.lastTrans()
        else:
            current = None
        while current is not None and current is not new_last:
            next_current = current.prevTrans() if current.prevTrans is not None else None
            current.trans = NULL
            current.prevTrans = None
            current = next_current
        if new_last is None:
            self.lastTrans = None
        elif current is new_last:
            self.lastTrans = weakref.ref(new_last)
        else:
            raise ValueError("target not found in the transaction chain")

    def free(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_dbFreeRollback (self.db)
            self.db = NULL
        return factory.handleCode(rc)

    def _validate(self):
        cdef RDM_RETCODE rc
        if self.tfs is None:
            rc = eINVFCNSEQ
        else:
            tfs_obj = self.tfs()
            if tfs_obj is None:
                rc = eINVFCNSEQ
            else:
                if self.db == NULL:
                    rc = eINVFCNSEQ
                else:
                    rc = (<_ValidateTfs>tfs_obj)._validate()
        return rc

cdef class _ValidateCursor:
    def __init__(self, _ValidateDb db, token):
        if token is not _token:
            raise TypeError("This class cannot be instantiated directly. Please use a get method, such as rdm.dbapi.RdmDb.getRows()")
        rc = db._validate()
        if rc == sOKAY:
            self.db = weakref.ref(db)
            self.closeNumber = db.closeCount
            rc = rdm_dbAllocCursor(db.db, &self.cursor)
        factory.handleCode(rc)

    def __dealloc__(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rdm_cursorFree (self.cursor)

    def free(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorFree (self.cursor)
            self.cursor = NULL
        return factory.handleCode(rc)

    def _validate(self):
        cdef RDM_RETCODE rc
        if self.db is None:
            rc = eINVFCNSEQ
        else:
            db_obj = self.db()
            if db_obj is None:
                rc = eINVFCNSEQ
            elif self.cursor == NULL:
                rc = eINVFCNSEQ
            elif self.closeNumber != (<_ValidateDb>db_obj).closeCount:
                rc = eINVFCNSEQ
            else:
                rc = (<_ValidateDb>db_obj)._validate()
        return rc

cdef class _ValidateTrans:
    def __init__(self, _ValidateDb db, bool update, token):
        cdef RDM_RETCODE rc
        if token is not _token:
            raise TypeError("This class cannot be instantiated directly. Please use a start method, such as rdm.dbapi.RdmDb.startRead()")
        rc = db._validate()
        if rc == sOKAY:
            self.db = weakref.ref(db)
            self.prevTrans = db.lastTrans
            db.lastTrans = weakref.ref(self)
            if (update):
                with nogil:
                    rc = rdm_dbStartUpdate(db.db, RDM_LOCK_ALL, 0, RDM_LOCK_ALL, 0, &self.trans)
            else:
                with nogil:
                    rc = rdm_dbStartRead(db.db, RDM_LOCK_ALL, 0, &self.trans)
        factory.handleCode(rc)

    def __dealloc__(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rdm_transFree (self.trans)

    def free(self):
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_transFree (self.trans)
            self.trans = NULL
        return factory.handleCode(rc)

    def _validate(self):
        cdef RDM_RETCODE rc
        if self.db is None:
            rc = eINVFCNSEQ
        else:
            db_obj = self.db()
            if db_obj is None:
                rc = eINVFCNSEQ
            else:
                if self.trans == NULL:
                    rc = eINVFCNSEQ
                else:
                    rc = (<_ValidateDb>db_obj)._validate()
        return rc
