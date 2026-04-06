# cython: language_level=3
from .types cimport RDM_DB, RDM_CURSOR, RDM_TABLE_ID, RDM_KEY_ID, RDM_SEARCH_KEY, RDM_REF_ID
from .exceptions_factory import factory
from .retcodetypes import Status
from .retcodetypes cimport RDM_RETCODE, sOKAY, sNOTFOUND, eINVKEYID, eINVREFID, sENDOFCURSOR
from .validate cimport _ValidateCursor, _ValidateDb
from libc.stdint cimport intptr_t
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