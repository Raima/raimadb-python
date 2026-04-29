# cython: language_level=3

from .types cimport RDM_DB, RDM_CURSOR, RDM_RETCODE, RDM_OPEN_MODE, RDM_TABLE_ID, RDM_KEY_ID
from .types cimport RDM_TRANS_STATUS, RDM_TRANS_READ, RDM_TRANS_UPDATE, RDM_TRANS_SNAPSHOT
from .types cimport RDM_LOCK_STATUS, RDM_ENCRYPT
from .tfstypes cimport TFS_TYPE, RDM_TFS
from .exceptions_factory import factory
from .retcodetypes import Status
from .retcodetypes cimport RDM_RETCODE, sOKAY, eINVKEYID, eINVTABID
from .validate cimport _ValidateDb, _ValidateCursor, _ValidateEncrypt
from .cursorapi cimport RdmCursor
from .transapi cimport RdmTrans
from .validate cimport _token
from ._structwrapper cimport StructWrapper
from ._schemabuilder import _build_classes
from libc.stdint cimport intptr_t, uint32_t, uint64_t
from libc.stddef cimport size_t
from libc.stdlib cimport malloc, free

from typing import Tuple

cdef extern from "rdmdbapi.h":
    RDM_RETCODE rdm_dbClose(RDM_DB db) nogil
    RDM_RETCODE rdm_dbCloseRollback(RDM_DB db) nogil
    RDM_RETCODE rdm_dbFree(RDM_DB db) nogil
    RDM_RETCODE rdm_dbSetCatalog(RDM_DB db, const char *schema) nogil
    RDM_RETCODE rdm_dbSetCatalogFromFile(RDM_DB db, const char *catfile) nogil
    RDM_RETCODE rdm_dbCompileCatalog(RDM_DB db, const char *schema) nogil
    RDM_RETCODE rdm_dbCompileCatalogFromFile(RDM_DB db, const char *schemafile) nogil
    RDM_RETCODE rdm_dbLoadCatalog(RDM_DB db, const char *catalog) nogil
    RDM_RETCODE rdm_dbLoadCatalogFromFile(RDM_DB db, const char *catfile) nogil
    RDM_RETCODE rdm_dbAlterCatalog(RDM_DB db, const char *ddlStmt) nogil
    RDM_RETCODE rdm_dbOpen(RDM_DB db, const char *dbNameSpec, RDM_OPEN_MODE mode) nogil
    RDM_RETCODE rdm_dbSetDefaultValues (RDM_DB db, RDM_TABLE_ID tableId, void *colValues, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_dbInsertRow (RDM_DB db, RDM_TABLE_ID tableId, void *colValues, size_t bytesIn, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbGetRows (RDM_DB db, RDM_TABLE_ID tableId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbGetRowsByKey (RDM_DB db, RDM_KEY_ID keyId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbEnd(RDM_DB db) nogil
    RDM_RETCODE rdm_dbEndRollback(RDM_DB db) nogil
    RDM_RETCODE rdm_dbPrecommit(RDM_DB db) nogil
    RDM_RETCODE rdm_dbGetLockStatus(RDM_DB db, RDM_TABLE_ID tableId, RDM_LOCK_STATUS *status) nogil
    RDM_RETCODE rdm_dbGetTransactionStatus(RDM_DB db, RDM_TRANS_STATUS *status) nogil
    RDM_RETCODE rdm_dbEvictRowData(RDM_DB db, RDM_TABLE_ID evictTableId) nogil
    RDM_RETCODE rdm_dbEvictKeyData(RDM_DB db, RDM_KEY_ID evictKeyId) nogil
    RDM_RETCODE rdm_dbClearCache(RDM_DB db) nogil
    RDM_RETCODE rdm_dbGetOption(RDM_DB db, const char *keyword, char *optValue, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_dbGetOptions(RDM_DB db, char *optString, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_dbSetOption(RDM_DB db, const char *keyword, const char *strValue) nogil
    RDM_RETCODE rdm_dbSetOptions(RDM_DB db, const char *optString) nogil
    RDM_RETCODE rdm_dbDeleteAllRowsFromDatabase(RDM_DB db) nogil
    RDM_RETCODE rdm_dbDeleteAllRowsFromTable(RDM_DB db, RDM_TABLE_ID tableId) nogil
    RDM_RETCODE rdm_dbGetInfo(RDM_DB db, const char *keyword, char *infoString, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_dbGetMemoryUsage(RDM_DB db, uint64_t *systemCurr, uint64_t *systemMax, uint64_t *userCurr, uint64_t *userMax) nogil
    RDM_RETCODE rdm_dbGetTFSType(RDM_DB db, TFS_TYPE *pTfsType) nogil
    RDM_RETCODE rdm_dbFindPrimaryKeyIdByTableId(RDM_DB db, RDM_TABLE_ID tableId, RDM_KEY_ID *pKeyId) nogil
    RDM_RETCODE rdm_dbGetCertificate(RDM_DB db, char *certificate_info, size_t sizeIn, size_t *sizeOut) nogil
    RDM_RETCODE rdm_dbEncrypt(RDM_DB db, RDM_ENCRYPT enc, const char *optString) nogil
    RDM_RETCODE rdm_dbSetEncrypt(RDM_DB db, RDM_ENCRYPT enc) nogil
    RDM_RETCODE rdm_dbVacuum(RDM_DB db, const char *optString) nogil
    RDM_RETCODE rdm_dbCreateNewPackFile(RDM_DB db) nogil
    RDM_RETCODE rdm_dbPersistInMemory(RDM_DB db) nogil
    RDM_RETCODE rdm_dbTableSetMaxRows(RDM_DB db, RDM_TABLE_ID table, uint32_t maxrows) nogil

cdef class RdmDb(_ValidateDb):
    def allocCursor (self) -> Status:
        cdef RdmCursor cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = RdmCursor(self, _token)
        return factory.handleCode(rc), cursor
    
    def close(self) -> Status:
        """Close the database associated with this handle."""
        rc = self._validate()
        if rc == sOKAY:
            (<_ValidateDb>self).closeCount += 1
            rc = rdm_dbClose(self.db)
        return factory.handleCode(rc)

    def closeRollback(self) -> Status:
        """Close the database, rolling back any active transaction."""
        rc = self._validate()
        if rc == sOKAY:
            (<_ValidateDb>self).closeCount += 1
            rc = rdm_dbCloseRollback(self.db)
        return factory.handleCode(rc)

    def setCatalog(self, str catalog) -> Status:
        """Open the database with the specified name and mode."""
        cdef bytes b_catalog = catalog.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbSetCatalog(self.db, b_catalog)
        return factory.handleCode(rc)

    def open(self, str dbNameSpec, RDM_OPEN_MODE mode) -> Status:
        """Open the database with the specified name and mode."""
        cdef bytes b_dbNameSpec = dbNameSpec.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbOpen(self.db, b_dbNameSpec, mode)
        if rc == sOKAY:
            #_print_database_schema(self)
            _build_classes(self)
        return factory.handleCode(rc)

    def startUpdate(self) -> Tuple[Status, RdmTrans]:
        """Start an update transaction."""
        cdef RdmTrans trans = None
        rc = self._validate()
        if rc == sOKAY:
            trans = RdmTrans(self, RDM_TRANS_UPDATE, _token)
        return factory.handleCode(rc), trans

    def startRead(self) -> Tuple[Status, RdmTrans]:
        """Start a readtransaction."""
        cdef RdmTrans trans = None
        rc = self._validate()
        if rc == sOKAY:
            trans = RdmTrans(self, RDM_TRANS_READ, _token)
        return factory.handleCode(rc), trans

    def startSnapshot(self) -> Tuple[Status, RdmTrans]:
        """Start a snapshot transaction."""
        cdef RdmTrans trans = None
        rc = self._validate()
        if rc == sOKAY:
            trans = RdmTrans(self, RDM_TRANS_SNAPSHOT, _token)
        return factory.handleCode(rc), trans

    def insertRow(self, str table_name, **kwargs):
        """Insert a row of a given table with attributes for each column"""
        cdef table_class = self._tables[table_name]
        cdef RdmDb db = table_class._db
        cdef row = table_class()
        row._setAtRow(sOKAY)
        rdm_dbSetDefaultValues (db.db, table_class._table_id, <void *> <intptr_t> row._get_buffer(), row._get_size(), NULL)
        for key, value in kwargs.items():
            setattr(row, key, value)
        cdef RDM_RETCODE rc = rdm_dbInsertRow (db.db, row._get_id(), <void *> <intptr_t> row._get_buffer(), row._get_size(), &((<_ValidateCursor>row).cursor))
        return factory.handleCode(rc), row

    def getRows(self, str table_name):
        """Get rows from a table"""
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        cdef RdmDb db
        cdef rows
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            db = table_class._db
            rows = table_class()
            rdm_dbSetDefaultValues (db.db, table_class._table_id, <void *> <intptr_t> rows._get_buffer(), rows._get_size(), NULL)
            rc = rdm_dbGetRows (db.db, rows._get_id(), &((<_ValidateCursor>rows).cursor))
        return factory.handleCode(rc), rows

    def getRowsByKey(self, str table_name, str key_name):
        """Get rows from a table in key order"""
        cdef RDM_RETCODE rc = sOKAY
        cdef RdmDb db
        cdef rows
        cdef key_class
        cdef table_class
        try:
            table_class = self._tables[table_name]
            try:
                key_class = self._keys[table_name, key_name]
            except KeyError:
                rc = eINVKEYID
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            db = table_class._db
            rows = table_class()
            rdm_dbSetDefaultValues (db.db, table_class._table_id, <void *> <intptr_t> rows._get_buffer(), rows._get_size(), NULL)
            rc = rdm_dbGetRowsByKey (db.db, key_class._get_id(), &((<_ValidateCursor>rows).cursor))
        return factory.handleCode(rc), rows

    def getKey(self, str table_name, str key_name):
        """Get a row class with attributes for each column"""
        return self._keys[table_name, key_name]
