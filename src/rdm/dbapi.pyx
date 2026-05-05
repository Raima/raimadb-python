# cython: language_level=3

from .types cimport RDM_DB, RDM_CURSOR, RDM_RETCODE, RDM_OPEN_MODE, RDM_TABLE_ID, RDM_KEY_ID
from .types cimport RDM_TRANS_STATUS, RDM_TRANS_READ, RDM_TRANS_UPDATE, RDM_TRANS_SNAPSHOT, RDM_TRANS_SCHEMA_UPDATE
from .types cimport RDM_LOCK_STATUS, RDM_ENCRYPT
from .types cimport RDM_LOCK_SCHEMA
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

    def startSchemaUpdate(self) -> Tuple[Status, RdmTrans]:
        """Start an update transaction with a write lock on the schema (for alterCatalog)."""
        cdef RdmTrans trans = None
        rc = self._validate()
        if rc == sOKAY:
            trans = RdmTrans(self, <RDM_TRANS_STATUS> RDM_TRANS_SCHEMA_UPDATE, _token)
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

    # ------------------------------------------------------------------
    # Catalog management
    # ------------------------------------------------------------------
    def setCatalogFromFile(self, str catfile) -> Status:
        """Set the catalog from a catalog file."""
        cdef bytes b = catfile.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbSetCatalogFromFile(self.db, b)
        return factory.handleCode(rc)

    def compileCatalog(self, str schema) -> Status:
        """Compile a DDL schema string into the catalog."""
        cdef bytes b = schema.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbCompileCatalog(self.db, b)
        return factory.handleCode(rc)

    def compileCatalogFromFile(self, str schemafile) -> Status:
        """Compile a DDL schema file into the catalog."""
        cdef bytes b = schemafile.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbCompileCatalogFromFile(self.db, b)
        return factory.handleCode(rc)

    def loadCatalog(self, bytes catalog) -> Status:
        """Load a pre-compiled binary catalog."""
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbLoadCatalog(self.db, catalog)
        return factory.handleCode(rc)

    def loadCatalogFromFile(self, str catfile) -> Status:
        """Load a pre-compiled catalog from a file."""
        cdef bytes b = catfile.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbLoadCatalogFromFile(self.db, b)
        return factory.handleCode(rc)

    def alterCatalog(self, str ddlStmt) -> Status:
        """Alter the catalog using a DDL statement."""
        cdef bytes b = ddlStmt.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbAlterCatalog(self.db, b)
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Options
    # ------------------------------------------------------------------
    def setOption(self, str keyword, str value) -> Status:
        """Set a single option by keyword."""
        cdef bytes b_keyword = keyword.encode('utf-8')
        cdef bytes b_value = value.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbSetOption(self.db, b_keyword, b_value)
        return factory.handleCode(rc)

    def setOptions(self, str optString) -> Status:
        """Set options from a key=value string."""
        cdef bytes b = optString.encode('utf-8')
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbSetOptions(self.db, b)
        return factory.handleCode(rc)

    def getOption(self, str keyword) -> Tuple[Status, str]:
        """Get a single option by keyword."""
        cdef bytes b_keyword = keyword.encode('utf-8')
        cdef size_t needed = 0
        cdef char *buf = NULL
        cdef RDM_RETCODE rc = self._validate()
        cdef str result = ""
        if rc == sOKAY:
            rc = rdm_dbGetOption(self.db, b_keyword, NULL, 0, &needed)
            if rc == sOKAY and needed > 0:
                buf = <char *> malloc(needed)
                if buf == NULL:
                    raise MemoryError()
                try:
                    rc = rdm_dbGetOption(self.db, b_keyword, buf, needed, NULL)
                    if rc == sOKAY:
                        result = buf[:needed].decode('utf-8').rstrip('\x00')
                finally:
                    free(buf)
        return factory.handleCode(rc), result

    def getOptions(self) -> Tuple[Status, str]:
        """Get all options as a key=value string."""
        cdef size_t needed = 0
        cdef char *buf = NULL
        cdef RDM_RETCODE rc = self._validate()
        cdef str result = ""
        if rc == sOKAY:
            rc = rdm_dbGetOptions(self.db, NULL, 0, &needed)
            if rc == sOKAY and needed > 0:
                buf = <char *> malloc(needed)
                if buf == NULL:
                    raise MemoryError()
                try:
                    rc = rdm_dbGetOptions(self.db, buf, needed, NULL)
                    if rc == sOKAY:
                        result = buf[:needed].decode('utf-8').rstrip('\x00')
                finally:
                    free(buf)
        return factory.handleCode(rc), result

    def clearCache(self) -> Status:
        """Clear the in-memory cache."""
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbClearCache(self.db)
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Transaction control
    # ------------------------------------------------------------------
    def end(self) -> Status:
        """Commit the active transaction and release locks."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_dbEnd(self.db)
            (<_ValidateDb>self)._chainEnd(None, False)
        return factory.handleCode(rc)

    def endRollback(self) -> Status:
        """Roll back the active transaction and release locks."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_dbEndRollback(self.db)
            (<_ValidateDb>self)._chainEnd(None, False)
        return factory.handleCode(rc)

    def precommit(self) -> Status:
        """Two-phase precommit of the active transaction."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            with nogil:
                rc = rdm_dbPrecommit(self.db)
        return factory.handleCode(rc)

    def getLockStatus(self, str table_name) -> Tuple[Status, int]:
        """Query the lock status for a table."""
        cdef RDM_LOCK_STATUS status = <RDM_LOCK_STATUS> 0
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbGetLockStatus(self.db, table_class._table_id, &status)
        return factory.handleCode(rc), <int> status

    def getTransactionStatus(self) -> Tuple[Status, int]:
        """Query the active transaction type."""
        cdef RDM_TRANS_STATUS status = <RDM_TRANS_STATUS> 0
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbGetTransactionStatus(self.db, &status)
        return factory.handleCode(rc), <int> status

    def evictRowData(self, str table_name) -> Status:
        """Evict rows for a table from the runtime cache."""
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbEvictRowData(self.db, table_class._table_id)
        return factory.handleCode(rc)

    def evictKeyData(self, str table_name, str key_name) -> Status:
        """Evict key entries for an index from the runtime cache."""
        cdef RDM_RETCODE rc = sOKAY
        cdef key_class
        try:
            self._tables[table_name]
            try:
                key_class = self._keys[table_name, key_name]
            except KeyError:
                rc = eINVKEYID
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbEvictKeyData(self.db, key_class._get_id())
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------
    def deleteAllRowsFromDatabase(self) -> Status:
        """Delete all rows from every table in the database."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbDeleteAllRowsFromDatabase(self.db)
        return factory.handleCode(rc)

    def deleteAllRowsFromTable(self, str table_name) -> Status:
        """Delete all rows from the named table."""
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbDeleteAllRowsFromTable(self.db, table_class._table_id)
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Information
    # ------------------------------------------------------------------
    def getInfo(self, str keyword) -> Tuple[Status, str]:
        """Get database information as a JSON string."""
        cdef bytes b_keyword = keyword.encode('utf-8')
        cdef size_t bufsize = 4096
        cdef size_t needed = 0
        cdef char *buf
        cdef RDM_RETCODE rc = self._validate()
        cdef str result = ""
        if rc == sOKAY:
            buf = <char *> malloc(bufsize)
            if buf == NULL:
                raise MemoryError()
            try:
                rc = rdm_dbGetInfo(self.db, b_keyword, buf, bufsize, &needed)
                if rc == sOKAY:
                    result = buf[:needed].decode('utf-8').rstrip('\x00')
            finally:
                free(buf)
        return factory.handleCode(rc), result

    def getMemoryUsage(self) -> Tuple[Status, dict]:
        """Get system and user memory usage statistics."""
        cdef uint64_t systemCurr = 0
        cdef uint64_t systemMax = 0
        cdef uint64_t userCurr = 0
        cdef uint64_t userMax = 0
        cdef RDM_RETCODE rc = self._validate()
        cdef dict result = {}
        if rc == sOKAY:
            rc = rdm_dbGetMemoryUsage(self.db, &systemCurr, &systemMax, &userCurr, &userMax)
            if rc == sOKAY:
                result = {
                    'systemCurr': systemCurr,
                    'systemMax': systemMax,
                    'userCurr': userCurr,
                    'userMax': userMax,
                }
        return factory.handleCode(rc), result

    def getTFS(self):
        """Get the parent TFS handle for this database."""
        if self.tfs is None:
            return None
        return self.tfs()

    def getTFSType(self) -> Tuple[Status, int]:
        """Get the TFS type enum."""
        cdef TFS_TYPE tfsType = <TFS_TYPE> 0
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbGetTFSType(self.db, &tfsType)
        return factory.handleCode(rc), <int> tfsType

    def findPrimaryKeyIdByTableId(self, str table_name) -> Tuple[Status, int]:
        """Get the primary key ID for a table."""
        cdef RDM_KEY_ID keyId = 0
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbFindPrimaryKeyIdByTableId(self.db, table_class._table_id, &keyId)
        return factory.handleCode(rc), <int> keyId

    def getCertificate(self) -> Tuple[Status, str]:
        """Get the server's SSL certificate (PEM)."""
        cdef size_t needed = 0
        cdef char *buf = NULL
        cdef RDM_RETCODE rc = self._validate()
        cdef str result = ""
        if rc == sOKAY:
            rc = rdm_dbGetCertificate(self.db, NULL, 0, &needed)
            if rc == sOKAY and needed > 0:
                buf = <char *> malloc(needed)
                if buf == NULL:
                    raise MemoryError()
                try:
                    rc = rdm_dbGetCertificate(self.db, buf, needed, NULL)
                    if rc == sOKAY:
                        result = buf[:needed].decode('utf-8').rstrip('\x00')
                finally:
                    free(buf)
        return factory.handleCode(rc), result

    # ------------------------------------------------------------------
    # Encryption
    # ------------------------------------------------------------------
    def setEncrypt(self, _ValidateEncrypt enc) -> Status:
        """Associate an encryption context with this database handle."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = enc._validate()
        if rc == sOKAY:
            rc = rdm_dbSetEncrypt(self.db, enc.enc)
        return factory.handleCode(rc)

    def encrypt(self, _ValidateEncrypt enc, str optString = None) -> Status:
        """Encrypt, decrypt, or re-encrypt the database."""
        cdef bytes b_opt
        cdef const char *c_opt = NULL
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = enc._validate()
        if rc == sOKAY:
            if optString is not None:
                b_opt = optString.encode('utf-8')
                c_opt = b_opt
            rc = rdm_dbEncrypt(self.db, enc.enc, c_opt)
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Utilities
    # ------------------------------------------------------------------
    def vacuum(self, str optString = None) -> Status:
        """Compact pack files."""
        cdef bytes b_opt
        cdef const char *c_opt = NULL
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            if optString is not None:
                b_opt = optString.encode('utf-8')
                c_opt = b_opt
            rc = rdm_dbVacuum(self.db, c_opt)
        return factory.handleCode(rc)

    def createNewPackFile(self) -> Status:
        """Force creation of a new pack file."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbCreateNewPackFile(self.db)
        return factory.handleCode(rc)

    def persistInMemory(self) -> Status:
        """Flush in-memory tables to disk."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbPersistInMemory(self.db)
        return factory.handleCode(rc)

    def tableSetMaxRows(self, str table_name, uint32_t maxrows) -> Status:
        """Cap the row count on a table."""
        cdef RDM_RETCODE rc = sOKAY
        cdef table_class
        try:
            table_class = self._tables[table_name]
        except KeyError:
            rc = eINVTABID
        if rc == sOKAY:
            rc = self._validate()
        if rc == sOKAY:
            rc = rdm_dbTableSetMaxRows(self.db, table_class._table_id, maxrows)
        return factory.handleCode(rc)
