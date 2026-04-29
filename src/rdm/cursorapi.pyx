# cython: language_level=3
from .types cimport (
    RDM_DB, RDM_CURSOR, RDM_TABLE_ID, RDM_KEY_ID, RDM_SEARCH_KEY, RDM_REF_ID,
    RDM_CURSOR_STATUS, RDM_CURSOR_TYPE, RDM_LOCK_STATUS, RDM_ROWID_T,
)
from .types import CursorStatus, CursorType, LockStatus
from .exceptions_factory import factory
from .retcodetypes import Status
from .retcodetypes cimport RDM_RETCODE, sOKAY, sNOTFOUND, eINVKEYID, eINVREFID, sENDOFCURSOR
from .validate cimport _ValidateCursor, _ValidateDb
from libc.stdint cimport intptr_t, uint64_t
from libcpp cimport bool as cppbool
cdef extern from "rdmcursorapi.h":
    RDM_RETCODE rdm_cursorMoveToBeforeFirst (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorMoveToFirst (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorMoveToNext (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorMoveToPrevious (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorMoveToLast (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorMoveToAfterLast (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorUpdateRow (RDM_CURSOR cursor, void *colValues, size_t bytesIn) nogil
    RDM_RETCODE rdm_cursorReadRow (RDM_CURSOR cursor, void *colValues, size_t bytesIn, size_t *pBytesOut) nogil
    RDM_RETCODE rdm_cursorFree(RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorSetDefaultValues (RDM_CURSOR cursor, void *colValues, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_cursorMoveToKey (RDM_CURSOR cursor, RDM_KEY_ID keyId, const void *keyValue, size_t bytesIn) nogil
    RDM_RETCODE rdm_cursorMoveToSearchKey (RDM_CURSOR cursor, RDM_KEY_ID keyId, const RDM_SEARCH_KEY *keyValue) nogil
    RDM_RETCODE rdm_cursorGetMemberRows (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetOwnerRow (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetSiblingRows (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetSiblingRowsAtPosition (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorComparePosition (RDM_CURSOR cursorPrimary, RDM_CURSOR cursorSecondary, RDM_CURSOR_COMPARE *comparison) nogil
    RDM_RETCODE rdm_cursorMoveToPosition (RDM_CURSOR cursor1, RDM_CURSOR cursor2) nogil
    RDM_RETCODE rdm_cursorMoveToRowId (RDM_CURSOR cursor, RDM_ROWID_T rowid) nogil
    RDM_RETCODE rdm_cursorGetStatus (RDM_CURSOR cursor, RDM_CURSOR_STATUS *position) nogil
    RDM_RETCODE rdm_cursorGetType (RDM_CURSOR cursor, RDM_CURSOR_TYPE *type) nogil
    RDM_RETCODE rdm_cursorGetTableId (RDM_CURSOR cursor, RDM_TABLE_ID *tableId) nogil
    RDM_RETCODE rdm_cursorGetRowId (RDM_CURSOR cursor, RDM_ROWID_T *rowid) nogil
    RDM_RETCODE rdm_cursorGetCount (RDM_CURSOR cursor, uint64_t *count) nogil
    RDM_RETCODE rdm_cursorGetLockStatus (RDM_CURSOR cursor, RDM_LOCK_STATUS *status) nogil
    RDM_RETCODE rdm_cursorIsAfterLast (RDM_CURSOR cursor, cppbool *isAfterLast) nogil
    RDM_RETCODE rdm_cursorIsBeforeFirst (RDM_CURSOR cursor, cppbool *isBeforeFirst) nogil
    RDM_RETCODE rdm_cursorGetClone (RDM_CURSOR sourceCursor, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetSelf (RDM_CURSOR sourceCursor, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetRowsAtPosition (RDM_CURSOR sourceCursor, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetRowsByKeyAtPosition (RDM_CURSOR sourceCursor, RDM_KEY_ID keyId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorGetRowsInReverseOrder (RDM_CURSOR sourceCursor, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_cursorDeleteRow (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorUnlinkAndDeleteRow (RDM_CURSOR cursor) nogil
    RDM_RETCODE rdm_cursorAddMember (RDM_CURSOR setCursor, RDM_CURSOR memberCursor) nogil
    RDM_RETCODE rdm_cursorRemoveMember (RDM_CURSOR setCursor) nogil
    RDM_RETCODE rdm_cursorLinkRow (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR cursorOwner) nogil
    RDM_RETCODE rdm_cursorRelinkRow (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_CURSOR cursorOwner) nogil
    RDM_RETCODE rdm_cursorUnlinkRow (RDM_CURSOR cursor, RDM_REF_ID refId) nogil
    RDM_RETCODE rdm_cursorHasMembers (RDM_CURSOR cursor, RDM_REF_ID refId, cppbool *hasMembers) nogil
    RDM_RETCODE rdm_cursorHasOwner (RDM_CURSOR cursor, RDM_REF_ID refId, cppbool *hasOwner) nogil
    RDM_RETCODE rdm_cursorGetMemberCount (RDM_CURSOR cursor, RDM_REF_ID refId, uint64_t *memberCount) nogil
    RDM_RETCODE rdm_cursorGetOwnerRowId (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_ROWID_T *rowid) nogil
    RDM_RETCODE rdm_cursorGetOwnerTableId (RDM_CURSOR cursor, RDM_REF_ID refId, RDM_TABLE_ID *tableId) nogil

cdef class RdmCursor(_ValidateCursor):
    def __init__ (self, _ValidateDb db, token):
        _ValidateCursor.__init__(self, db, token)
        self.at_row = False

    cpdef _isAtRow (self):
        return self.at_row

    def _setAtRow (self, RDM_RETCODE rc):
        if rc == sOKAY:
            self.at_row = True
        elif rc == sENDOFCURSOR or rc == sNOTFOUND:
            self.at_row = False

    def free(self) -> Status:
        """Free the cursor handle and its resources."""
        rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorFree(self.cursor)
            self.cursor = NULL
        return factory.handleCode(rc)

    def __iter__(self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToBeforeFirst(cursor)
        if rc == sOKAY:
            self.at_row = False
        factory.handleCode(rc)
        return self

    def __next__(self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToNext(cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        if rc == sENDOFCURSOR:
            raise StopIteration
        factory.handleCode(rc)
        return self
           
    def moveToBeforeFirst (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToBeforeFirst(cursor)
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc)

    def moveToFirst (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToFirst(cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        return factory.handleCode(rc)

    def moveToNext (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToNext(cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        return factory.handleCode(rc)

    def moveToPrevious (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToPrevious(cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        return factory.handleCode(rc)

    def moveToLast (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToLast(cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        return factory.handleCode(rc)

    def moveToAfterLast (self):
        cdef RDM_CURSOR cursor
        rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToAfterLast(cursor)
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc)

    def moveToKey (self, str key_name, stringLen=0, **kwargs):
        """Position the cursor to the first row with the specified key value."""
        cdef RDM_RETCODE rc = self._validate()
        cdef key_class
        cdef RDM_SEARCH_KEY sk;
        if rc == sOKAY:
            try:
                key_class = self._db._keys[(self.__class__.__name__, key_name)]
            except KeyError:
                rc = eINVKEYID
        if rc == sOKAY:
            if stringLen > 0 and len(kwargs) != len(key_class._field_info):
                raise ValueError("Must provide values for all key elements when specifying a string length")
            key = key_class()
            key._setAtRow(sOKAY)
            for name, value in kwargs.items():
                setattr(key, name, value)
            sk.value = <void *> <intptr_t> key._get_buffer()
            sk.bytesIn = key._get_size()
            sk.numKeyCols = key._get_num_keys()
            sk.stringLen = stringLen
            rc = rdm_cursorMoveToSearchKey((<_ValidateCursor>self).cursor, key_class._get_id(), &sk)
        if rc == sOKAY:
            rc = rdm_cursorReadRow((<_ValidateCursor>self).cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow (rc)
        return factory.handleCode(rc)

    def getMemberRows (self, str reference_name):
        """Get the member of a row for a given set"""
        cdef RDM_RETCODE rc = self._validate()
        cdef member_class
        cdef owner_class
        cdef members
        if rc == sOKAY:
            try:
                (reference_id, owner_class, member_class) = self._db._references [reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            if not isinstance(self, owner_class):
                rc = eINVREFID
        if rc == sOKAY:
            members = member_class()
            rc = rdm_cursorGetMemberRows ((<_ValidateCursor>self).cursor, reference_id, &((<_ValidateCursor>members).cursor))
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc), members

    def getOwnerRow (self, str reference_name):
        """Get the owner of a row for a given set"""
        cdef RDM_RETCODE rc = self._validate()
        cdef member_class
        cdef owner_class
        cdef owner
        if rc == sOKAY:
            try:
                (reference_id, owner_class, member_class) = self._db._references [reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            if not isinstance(self, member_class):
                rc = eINVREFID
        if rc == sOKAY:
            owner = owner_class()
            rc = rdm_cursorGetOwnerRow ((<_ValidateCursor>self).cursor, reference_id, &((<_ValidateCursor>owner).cursor))
        self._setAtRow (rc)
        return factory.handleCode(rc), owner

    def getSiblingRows (self, str reference_name):
        """Get the siblings of a row for a given set"""
        cdef RDM_RETCODE rc = self._validate()
        cdef member_class
        cdef siblings
        if rc == sOKAY:
            try:
                (reference_id, _, member_class) = self._db._references [reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            if not isinstance(self, member_class):
                rc = eINVREFID
        if rc == sOKAY:
            siblings = member_class()
            rc = rdm_cursorGetSiblingRows ((<_ValidateCursor>self).cursor, reference_id, &((<_ValidateCursor>siblings).cursor))
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc), siblings

    def getSiblingRowsAtPosition (self, str reference_name):
        """Get the siblings of a row for a given set positioned at the source row"""
        cdef RDM_RETCODE rc = self._validate()
        cdef member_class
        cdef siblings
        if rc == sOKAY:
            try:
                (reference_id, _, member_class) = self._db._references [reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            if not isinstance(self, member_class):
                rc = eINVREFID
        if rc == sOKAY:
            siblings = member_class()
            rc = rdm_cursorGetSiblingRowsAtPosition ((<_ValidateCursor>self).cursor, reference_id, &((<_ValidateCursor>siblings).cursor))
        self._setAtRow (rc)
        return factory.handleCode(rc), siblings

    def update (self, **kwargs):
        cdef RDM_CURSOR cursor = (<_ValidateCursor>self).cursor
        for key, value in kwargs.items():
            setattr(self, key, value)
        rc = rdm_cursorUpdateRow (cursor, <void *> <intptr_t> self._get_buffer(), self._get_size())
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Group A - Navigation
    # ------------------------------------------------------------------
    def moveToPosition (self, RdmCursor other):
        """Move this cursor to the position of another cursor."""
        cdef RDM_CURSOR cursor
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = other._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToPosition(cursor, (<_ValidateCursor>other).cursor)
        if rc == sOKAY:
            rc = rdm_cursorReadRow(cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow(rc)
        return factory.handleCode(rc)

    def moveToRowId (self, rowid):
        """Move this cursor to the row with the given row id."""
        cdef RDM_CURSOR cursor
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            cursor = (<_ValidateCursor>self).cursor
            rc = rdm_cursorMoveToRowId(cursor, <RDM_ROWID_T>rowid)
        if rc == sOKAY:
            rc = rdm_cursorReadRow(cursor, <void *> <intptr_t> self._get_buffer(), self._get_size(), NULL)
        self._setAtRow(rc)
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Group B - Status / Inspection
    # ------------------------------------------------------------------
    def getStatus (self):
        """Get the position status of the cursor."""
        cdef RDM_CURSOR_STATUS position
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetStatus((<_ValidateCursor>self).cursor, &position)
        factory.handleCodeWithNoStatus(rc)
        return CursorStatus(<int>position)

    def getType (self):
        """Get the type of the cursor."""
        cdef RDM_CURSOR_TYPE ctype
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetType((<_ValidateCursor>self).cursor, &ctype)
        factory.handleCodeWithNoStatus(rc)
        return CursorType(<int>ctype)

    def getTableId (self):
        """Get the table id associated with the cursor."""
        cdef RDM_TABLE_ID tableId
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetTableId((<_ValidateCursor>self).cursor, &tableId)
        factory.handleCodeWithNoStatus(rc)
        return <int>tableId

    def getRowId (self):
        """Get the row id of the row at the current cursor position."""
        cdef RDM_ROWID_T rowid
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetRowId((<_ValidateCursor>self).cursor, &rowid)
        factory.handleCodeWithNoStatus(rc)
        return <object><uint64_t>rowid

    def getCount (self):
        """Get the number of rows accessible through the cursor."""
        cdef uint64_t count
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetCount((<_ValidateCursor>self).cursor, &count)
        factory.handleCodeWithNoStatus(rc)
        return <object>count

    def getLockStatus (self):
        """Get the lock status of the cursor's table."""
        cdef RDM_LOCK_STATUS status
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorGetLockStatus((<_ValidateCursor>self).cursor, &status)
        factory.handleCodeWithNoStatus(rc)
        return LockStatus(<int>status)

    def isAfterLast (self):
        """Return True if the cursor is positioned after the last row."""
        cdef cppbool flag = False
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorIsAfterLast((<_ValidateCursor>self).cursor, &flag)
        factory.handleCodeWithNoStatus(rc)
        return bool(flag)

    def isBeforeFirst (self):
        """Return True if the cursor is positioned before the first row."""
        cdef cppbool flag = False
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorIsBeforeFirst((<_ValidateCursor>self).cursor, &flag)
        factory.handleCodeWithNoStatus(rc)
        return bool(flag)

    def getDatabase (self):
        """Return the RdmDb instance this cursor belongs to."""
        return self._db

    # ------------------------------------------------------------------
    # Group C - Cursor derivation
    # ------------------------------------------------------------------
    def getClone (self):
        """Return a new cursor that is an independent clone of this cursor."""
        cdef RDM_RETCODE rc = self._validate()
        cdef clone
        if rc == sOKAY:
            clone = self.__class__()
            rc = rdm_cursorGetClone((<_ValidateCursor>self).cursor, &((<_ValidateCursor>clone).cursor))
        if rc == sOKAY:
            (<RdmCursor>clone).at_row = self.at_row
            if self.at_row:
                rc = rdm_cursorReadRow(
                    (<_ValidateCursor>clone).cursor,
                    <void *> <intptr_t> clone._get_buffer(),
                    clone._get_size(),
                    NULL,
                )
        return factory.handleCode(rc), clone

    def getSelf (self):
        """Return a new cursor positioned only at the current row of this cursor."""
        cdef RDM_RETCODE rc = self._validate()
        cdef new_cursor
        if rc == sOKAY:
            new_cursor = self.__class__()
            rc = rdm_cursorGetSelf((<_ValidateCursor>self).cursor, &((<_ValidateCursor>new_cursor).cursor))
        if rc == sOKAY:
            (<RdmCursor>new_cursor).at_row = self.at_row
            if self.at_row:
                rc = rdm_cursorReadRow(
                    (<_ValidateCursor>new_cursor).cursor,
                    <void *> <intptr_t> new_cursor._get_buffer(),
                    new_cursor._get_size(),
                    NULL,
                )
        return factory.handleCode(rc), new_cursor

    def getRowsAtPosition (self):
        """Return a new cursor over the same rows, positioned at the current row."""
        cdef RDM_RETCODE rc = self._validate()
        cdef new_cursor
        if rc == sOKAY:
            new_cursor = self.__class__()
            rc = rdm_cursorGetRowsAtPosition((<_ValidateCursor>self).cursor, &((<_ValidateCursor>new_cursor).cursor))
        if rc == sOKAY:
            (<RdmCursor>new_cursor).at_row = self.at_row
            if self.at_row:
                rc = rdm_cursorReadRow(
                    (<_ValidateCursor>new_cursor).cursor,
                    <void *> <intptr_t> new_cursor._get_buffer(),
                    new_cursor._get_size(),
                    NULL,
                )
        return factory.handleCode(rc), new_cursor

    def getRowsByKeyAtPosition (self, str key_name):
        """Return a new cursor ordered by the given key, positioned at the current row."""
        cdef RDM_RETCODE rc = self._validate()
        cdef key_class
        cdef new_cursor
        if rc == sOKAY:
            try:
                key_class = self._db._keys[(self.__class__.__name__, key_name)]
            except KeyError:
                rc = eINVKEYID
        if rc == sOKAY:
            new_cursor = self.__class__()
            rc = rdm_cursorGetRowsByKeyAtPosition(
                (<_ValidateCursor>self).cursor,
                key_class._get_id(),
                &((<_ValidateCursor>new_cursor).cursor),
            )
        if rc == sOKAY:
            (<RdmCursor>new_cursor).at_row = self.at_row
            if self.at_row:
                rc = rdm_cursorReadRow(
                    (<_ValidateCursor>new_cursor).cursor,
                    <void *> <intptr_t> new_cursor._get_buffer(),
                    new_cursor._get_size(),
                    NULL,
                )
        return factory.handleCode(rc), new_cursor

    def getRowsInReverseOrder (self):
        """Return a new cursor that iterates the same rows in reverse order."""
        cdef RDM_RETCODE rc = self._validate()
        cdef new_cursor
        if rc == sOKAY:
            new_cursor = self.__class__()
            rc = rdm_cursorGetRowsInReverseOrder((<_ValidateCursor>self).cursor, &((<_ValidateCursor>new_cursor).cursor))
        if rc == sOKAY:
            (<RdmCursor>new_cursor).at_row = False
        return factory.handleCode(rc), new_cursor

    # ------------------------------------------------------------------
    # Group D - Delete
    # ------------------------------------------------------------------
    def deleteRow (self):
        """Delete the row at the current cursor position."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorDeleteRow((<_ValidateCursor>self).cursor)
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc)

    def unlinkAndDeleteRow (self):
        """Unlink the row from all sets and delete it."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorUnlinkAndDeleteRow((<_ValidateCursor>self).cursor)
        if rc == sOKAY:
            self.at_row = False
        return factory.handleCode(rc)

    # ------------------------------------------------------------------
    # Group F - Set membership
    # ------------------------------------------------------------------
    def addMember (self, RdmCursor member_cursor):
        """Add the row referenced by member_cursor as a member of this set cursor."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = member_cursor._validate()
        if rc == sOKAY:
            rc = rdm_cursorAddMember(
                (<_ValidateCursor>self).cursor,
                (<_ValidateCursor>member_cursor).cursor,
            )
        return factory.handleCode(rc)

    def removeMember (self):
        """Remove the row at the current cursor position from its set."""
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = rdm_cursorRemoveMember((<_ValidateCursor>self).cursor)
        return factory.handleCode(rc)

    def linkRow (self, str reference_name, RdmCursor owner_cursor):
        """Link the row at this cursor to the given owner row via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        if rc == sOKAY:
            rc = owner_cursor._validate()
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorLinkRow(
                (<_ValidateCursor>self).cursor,
                <RDM_REF_ID>reference_id,
                (<_ValidateCursor>owner_cursor).cursor,
            )
        return factory.handleCode(rc)

    def relinkRow (self, str reference_name, RdmCursor owner_cursor):
        """Relink the row at this cursor to a different owner via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        if rc == sOKAY:
            rc = owner_cursor._validate()
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorRelinkRow(
                (<_ValidateCursor>self).cursor,
                <RDM_REF_ID>reference_id,
                (<_ValidateCursor>owner_cursor).cursor,
            )
        return factory.handleCode(rc)

    def unlinkRow (self, str reference_name):
        """Unlink the row at this cursor from its owner via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorUnlinkRow((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id)
        return factory.handleCode(rc)

    def hasMembers (self, str reference_name):
        """Return True if the row at this cursor has members via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        cdef cppbool flag = False
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorHasMembers((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id, &flag)
        factory.handleCodeWithNoStatus(rc)
        return bool(flag)

    def hasOwner (self, str reference_name):
        """Return True if the row at this cursor has an owner via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        cdef cppbool flag = False
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorHasOwner((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id, &flag)
        factory.handleCodeWithNoStatus(rc)
        return bool(flag)

    def getMemberCount (self, str reference_name):
        """Return the number of members of the row at this cursor via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        cdef uint64_t count = 0
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorGetMemberCount((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id, &count)
        factory.handleCodeWithNoStatus(rc)
        return <object>count

    def getOwnerRowId (self, str reference_name):
        """Return the row id of the owner of the row at this cursor via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        cdef RDM_ROWID_T rowid = 0
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorGetOwnerRowId((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id, &rowid)
        factory.handleCodeWithNoStatus(rc)
        return <object><uint64_t>rowid

    def getOwnerTableId (self, str reference_name):
        """Return the table id of the owner of the row at this cursor via the named reference."""
        cdef RDM_RETCODE rc = self._validate()
        cdef reference_id
        cdef RDM_TABLE_ID tableId = 0
        if rc == sOKAY:
            try:
                (reference_id, _, _) = self._db._references[reference_name]
            except KeyError:
                rc = eINVREFID
        if rc == sOKAY:
            rc = rdm_cursorGetOwnerTableId((<_ValidateCursor>self).cursor, <RDM_REF_ID>reference_id, &tableId)
        factory.handleCodeWithNoStatus(rc)
        return <int>tableId

    cdef RDM_CURSOR_COMPARE _get_comparison(self, RdmCursor other) except *:
        cdef RDM_RETCODE rc = self._validate()
        if rc == sOKAY:
            rc = other._validate()
        cdef RDM_CURSOR_COMPARE comp
        if rc == sOKAY:
            rc = rdm_cursorComparePosition(self.cursor, other.cursor, &comp)
        factory.handleCodeWithNoStatus(rc)
        return comp

    def __lt__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        return self._get_comparison(other) == CURSOR_BEFORE
    def __le__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        cdef RDM_CURSOR_COMPARE comp = self._get_comparison(other)
        return comp == CURSOR_BEFORE or comp == CURSOR_EQUAL
    def __eq__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        return self._get_comparison(other) == CURSOR_EQUAL
    def __ne__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        return self._get_comparison(other) != CURSOR_EQUAL
    def __gt__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        return self._get_comparison(other) == CURSOR_AFTER
    def __ge__(self, other):
        if not isinstance(other, RdmCursor):
            return NotImplemented
        cdef RDM_CURSOR_COMPARE comp = self._get_comparison(other)
        return comp == CURSOR_AFTER or comp == CURSOR_EQUAL