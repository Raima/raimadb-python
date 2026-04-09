# cython: language_level=3

from .types cimport RDM_DB, RDM_CURSOR, RDM_RETCODE, RDM_OPEN_MODE, RDM_TABLE_ID, RDM_COLUMN_ID, RDM_KEY_ID, RDM_REF_ID
from .exceptions_factory import factory
from .retcodetypes import Status
from .retcodetypes cimport RDM_RETCODE, sOKAY, sNOTFOUND, eINVKEYID, eINVTABID
from .validate cimport _ValidateDb, _ValidateCursor
from .cursorapi cimport RdmCursor
from .transapi cimport RdmTrans
from .validate cimport _token
from libc.stdint cimport uint8_t, int8_t, uint16_t, int16_t, uint32_t, int32_t, uint64_t, int64_t, intptr_t

from cpython.object cimport PyObject
from cpython.bytes cimport PyBytes_FromStringAndSize

from typing import Tuple
from libc.string cimport memset
import uuid as _uuid_mod
import datetime as _datetime_mod

cdef extern from "rdmdatetimetypes.h":
    ctypedef uint32_t RDM_PACKED_DATE_T
    ctypedef uint32_t RDM_PACKED_TIME_T

    ctypedef struct RDM_PACKED_TIMESTAMP_T:
        RDM_PACKED_DATE_T date
        RDM_PACKED_TIME_T time

    ctypedef struct RDM_PACKED_TIMETZ_T:
        RDM_PACKED_TIME_T time
        int16_t tz

    ctypedef struct RDM_PACKED_TIMESTAMPTZ_T:
        RDM_PACKED_DATE_T date
        RDM_PACKED_TIME_T time
        int16_t tz

cdef extern from "rdmbcdtypes.h":
    ctypedef struct RDM_BCD_T:
        pass

cdef extern from "rdmuuidtypes.h":
    ctypedef struct RDM_UUID_T:
        uint32_t time_low
        uint16_t time_mid
        uint16_t time_high_and_version
        uint8_t clock_seq_high_and_reserved
        uint8_t clock_seq_low
        uint8_t node[6]

cdef extern from "rdmdbapi.h":
    RDM_RETCODE rdm_dbCloseRollback(RDM_DB db) nogil
    RDM_RETCODE rdm_dbFree(RDM_DB db) nogil
    RDM_RETCODE rdm_dbSetCatalog(RDM_DB db, const char *schema) nogil
    RDM_RETCODE rdm_dbOpen(RDM_DB db, const char *dbNameSpec, RDM_OPEN_MODE mode) nogil
    RDM_RETCODE rdm_dbSetDefaultValues (RDM_DB db, RDM_TABLE_ID tableId, void *colValues, size_t bytesIn, size_t *bytesOut) nogil
    RDM_RETCODE rdm_dbInsertRow (RDM_DB db, RDM_TABLE_ID tableId, void *colValues, size_t bytesIn, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbGetRows (RDM_DB db, RDM_TABLE_ID tableId, RDM_CURSOR *pCursor) nogil
    RDM_RETCODE rdm_dbGetRowsByKey (RDM_DB db, RDM_KEY_ID keyId, RDM_CURSOR *pCursor) nogil

# Declarations for BCD/Decimal conversion (extern "C" from bcd_convert.h)
cdef extern from "bcd_convert.h":
    int bcd_to_decimal(const RDM_BCD_T* bcd, PyObject **out)
    int decimal_to_bcd(PyObject *dec, RDM_BCD_T* out)

cdef extern from "table_column.h" namespace "RDM::RUNTIME":
    cdef enum RDM_TYPE:
        BOOLEAN = 0
        UINT8
        INT8
        UINT16
        INT16
        UINT32
        INT32
        UINT64
        INT64
        FLOAT32
        FLOAT64
        DECIMAL
        DATE
        TIME
        TIME_TZ
        TIMESTAMP
        TIMESTAMP_TZ
        ROWID
        UUID
        CHAR
        VARCHAR
        BINARY
        VARBINARY
        _BLOB
        _CLOB
        _UNKNOWN

cdef extern from "db_table.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_TABLE:
        DB_TABLE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_TABLE_ID getId() nogil
        uint32_t getSize() nogil

cdef extern from "table_column.h" namespace "RDM::RUNTIME":
    cdef cppclass TABLE_COLUMN:
        TABLE_COLUMN()
        void setTable(const DB_TABLE* table) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_COLUMN_ID getId() nogil
        RDM_TYPE getType() nogil
        uint32_t getOffset() nogil
        uint32_t getHasValueOffset() nogil
        bint getNullable() nogil
        uint32_t getSize() nogil
        uint16_t getArrayElements() nogil
        uint32_t getStringLength() nogil

cdef extern from "table_key.h" namespace "RDM::RUNTIME":
    cdef cppclass TABLE_KEY:
        TABLE_KEY()
        void setTable(const DB_TABLE* table) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_KEY_ID getId() nogil
        uint32_t getSize() nogil

cdef extern from "key_element.h" namespace "RDM::RUNTIME":
    cdef cppclass KEY_ELEMENT:
        KEY_ELEMENT()
        void setKey(const TABLE_KEY* key) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_TYPE getType() nogil
        uint32_t getOffset() nogil
        uint32_t getHasValueOffset() nogil
        bint getNullable() nogil
        uint32_t getSize() nogil
        uint16_t getArrayElements() nogil
        uint32_t getStringLength() nogil

cdef extern from "db_reference.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_REFERENCE:
        DB_REFERENCE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_REF_ID getId() nogil
        const char* getPrimaryTableName() nogil
        const char* getForeignTableName() nogil
        RDM_TABLE_ID getPrimaryTableId() nogil
        RDM_TABLE_ID getForeignTableId() nogil

cdef extern from "db_ud_type.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_UD_TYPE:
        DB_UD_TYPE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        uint32_t getSize() nogil

from libc.stdlib cimport malloc, free
from libc.string cimport memchr

cdef extern from "<arpa/inet.h>" nogil:
    uint32_t ntohl(uint32_t netlong)
    uint16_t ntohs(uint16_t netshort)
    uint32_t htonl(uint32_t hostlong)
    uint16_t htons(uint16_t hostshort)

cdef class StructWrapper (RdmCursor):
    cdef char* buffer
    cdef size_t size
    cdef uint32_t _set_bits

    def __init__(self):
        """Initialize the buffer with the class-specific size."""
        cdef RdmDb db = self.__class__._db
        super().__init__(db, _token)
        self.size = self.__class__.__size__
        self.buffer = <char*>malloc(self.size)
        if not self.buffer:
            raise MemoryError()
        memset(self.buffer, 0, self.size)
        self._set_bits = 0

    def __dealloc__(self):
        """Free the allocated buffer when the instance is destroyed."""
        if self.buffer:
            free(self.buffer)
        
    cpdef tuple _get_buffer_address_and_size(self):
        """Return the buffer's memory address and size as a tuple."""
        return (<intptr_t>self.buffer, self.size)

    cpdef _get_buffer(self):
        """Return the buffer's memory address."""
        return (<intptr_t>self.buffer)

    cpdef _get_size(self):
        """Return the buffer's size."""
        return self.size

    def _get_num_keys(self):
        """Return the number of consecutive prefix key fields set, or raise if not consecutive."""
        cdef int m = self._set_bits
        if m & (m + 1) != 0:
            raise ValueError("Set fields do not form a consecutive prefix")
        if m == 0:
            return 0
        import math
        return int(math.log2(m + 1))

    cdef object _get_uuid(self, size_t offset):
        """Read an RDM_UUID_T from the buffer and return a Python uuid.UUID.

        RDM stores time_low (uint32), time_mid (uint16), and
        time_high_and_version (uint16) in network byte order (big-endian).
        We convert them to host order before passing to uuid.UUID(fields=...).
        The remaining fields (clock_seq and node) are single bytes so they
        are byte-order neutral.
        """
        cdef RDM_UUID_T* u = <RDM_UUID_T*>(self.buffer + offset)
        return _uuid_mod.UUID(fields=(
            ntohl(u.time_low),
            ntohs(u.time_mid),
            ntohs(u.time_high_and_version),
            u.clock_seq_high_and_reserved,
            u.clock_seq_low,
            int.from_bytes(u.node[:6], byteorder='big'),
        ))

    cdef void _set_uuid(self, size_t offset, object value):
        """Write a Python uuid.UUID into the buffer as RDM_UUID_T.

        Accepts a uuid.UUID or a string that uuid.UUID can parse.
        Converts the first three fields from host order to network byte
        order (big-endian) before writing.
        """
        cdef RDM_UUID_T* u = <RDM_UUID_T*>(self.buffer + offset)
        if not isinstance(value, _uuid_mod.UUID):
            value = _uuid_mod.UUID(value)
        u.time_low = htonl(value.time_low)
        u.time_mid = htons(value.time_mid)
        u.time_high_and_version = htons(value.time_hi_version)
        u.clock_seq_high_and_reserved = value.clock_seq_hi_variant
        u.clock_seq_low = value.clock_seq_low
        cdef bytes node_bytes = value.node.to_bytes(6, byteorder='big')
        cdef size_t i
        for i in range(6):
            u.node[i] = node_bytes[i]

    cdef object _get_date(self, size_t offset):
        """Read an RDM_PACKED_DATE_T and return a datetime.date."""
        cdef uint32_t packed = (<uint32_t*>(self.buffer + offset))[0]
        return _datetime_mod.date.fromordinal(packed)

    cdef void _set_date(self, size_t offset, object value):
        """Write a datetime.date into the buffer as RDM_PACKED_DATE_T."""
        if not isinstance(value, _datetime_mod.date):
            raise TypeError("Expected a datetime.date")
        (<uint32_t*>(self.buffer + offset))[0] = <uint32_t>(value.toordinal())

    cdef object _get_time(self, size_t offset):
        """Read an RDM_PACKED_TIME_T and return a datetime.time."""
        cdef uint32_t packed = (<uint32_t*>(self.buffer + offset))[0]
        cdef uint32_t fraction = packed % 10000
        cdef uint32_t total_seconds = packed // 10000
        cdef uint16_t second = total_seconds % 60
        cdef uint32_t total_minutes = total_seconds // 60
        cdef uint16_t minute = total_minutes % 60
        cdef uint16_t hour = total_minutes // 60
        return _datetime_mod.time(hour, minute, second, fraction * 100)

    cdef void _set_time(self, size_t offset, object value):
        """Write a datetime.time into the buffer as RDM_PACKED_TIME_T."""
        if not isinstance(value, _datetime_mod.time):
            raise TypeError("Expected a datetime.time")
        cdef uint32_t packed = (<uint32_t>(value.hour) * 3600 + <uint32_t>(value.minute) * 60 + <uint32_t>(value.second)) * 10000 + <uint32_t>(value.microsecond) // 100
        (<uint32_t*>(self.buffer + offset))[0] = packed

    cdef object _get_time_tz(self, size_t offset):
        """Read an RDM_PACKED_TIMETZ_T and return a datetime.time with tzinfo.

        The buffer stores UTC time + tz offset.  We add the offset to
        obtain local time, using a dummy date to handle midnight wrap.
        """
        cdef RDM_PACKED_TIMETZ_T* t = <RDM_PACKED_TIMETZ_T*>(self.buffer + offset)
        cdef uint32_t packed = t.time
        cdef uint32_t fraction = packed % 10000
        cdef uint32_t total_seconds = packed // 10000
        cdef uint16_t second = total_seconds % 60
        cdef uint32_t total_minutes = total_seconds // 60
        cdef uint16_t minute = total_minutes % 60
        cdef uint16_t hour = total_minutes // 60
        cdef object tz_delta = _datetime_mod.timedelta(minutes=t.tz)
        cdef object tz = _datetime_mod.timezone(tz_delta)
        cdef object utc_dt = _datetime_mod.datetime(2000, 1, 1, hour, minute, second, fraction * 100)
        cdef object local_dt = utc_dt + tz_delta
        return local_dt.time().replace(tzinfo=tz)

    cdef void _set_time_tz(self, size_t offset, object value):
        """Write a datetime.time with tzinfo into the buffer as RDM_PACKED_TIMETZ_T.

        Converts local time to UTC before storing.
        """
        if not isinstance(value, _datetime_mod.time):
            raise TypeError("Expected a datetime.time")
        cdef RDM_PACKED_TIMETZ_T* t = <RDM_PACKED_TIMETZ_T*>(self.buffer + offset)
        cdef int tz_minutes = 0
        if value.tzinfo is not None:
            tz_minutes = int(value.utcoffset().total_seconds()) // 60
        cdef object local_dt = _datetime_mod.datetime(2000, 1, 1, value.hour, value.minute, value.second, value.microsecond)
        cdef object utc_dt = local_dt - _datetime_mod.timedelta(minutes=tz_minutes)
        t.time = (<uint32_t>(utc_dt.hour) * 3600 + <uint32_t>(utc_dt.minute) * 60 + <uint32_t>(utc_dt.second)) * 10000 + <uint32_t>(utc_dt.microsecond) // 100
        t.tz = <int16_t>tz_minutes

    cdef object _get_timestamp(self, size_t offset):
        """Read an RDM_PACKED_TIMESTAMP_T and return a datetime.datetime."""
        cdef RDM_PACKED_TIMESTAMP_T* ts = <RDM_PACKED_TIMESTAMP_T*>(self.buffer + offset)
        cdef object d = _datetime_mod.date.fromordinal(ts.date)
        cdef uint32_t packed = ts.time
        cdef uint32_t fraction = packed % 10000
        cdef uint32_t total_seconds = packed // 10000
        cdef uint16_t second = total_seconds % 60
        cdef uint32_t total_minutes = total_seconds // 60
        cdef uint16_t minute = total_minutes % 60
        cdef uint16_t hour = total_minutes // 60
        return _datetime_mod.datetime(d.year, d.month, d.day, hour, minute, second, fraction * 100)

    cdef void _set_timestamp(self, size_t offset, object value):
        """Write a datetime.datetime into the buffer as RDM_PACKED_TIMESTAMP_T."""
        if not isinstance(value, _datetime_mod.datetime):
            raise TypeError("Expected a datetime.datetime")
        cdef RDM_PACKED_TIMESTAMP_T* ts = <RDM_PACKED_TIMESTAMP_T*>(self.buffer + offset)
        ts.date = <uint32_t>(value.toordinal())
        ts.time = (<uint32_t>(value.hour) * 3600 + <uint32_t>(value.minute) * 60 + <uint32_t>(value.second)) * 10000 + <uint32_t>(value.microsecond) // 100

    cdef object _get_timestamp_tz(self, size_t offset):
        """Read an RDM_PACKED_TIMESTAMPTZ_T and return a datetime.datetime with tzinfo.

        The buffer stores UTC date/time + tz offset.  We add the offset
        to obtain local date/time (which may shift the date by +-1 day
        when crossing midnight).
        """
        cdef RDM_PACKED_TIMESTAMPTZ_T* ts = <RDM_PACKED_TIMESTAMPTZ_T*>(self.buffer + offset)
        cdef object d = _datetime_mod.date.fromordinal(ts.date)
        cdef uint32_t packed = ts.time
        cdef uint32_t fraction = packed % 10000
        cdef uint32_t total_seconds = packed // 10000
        cdef uint16_t second = total_seconds % 60
        cdef uint32_t total_minutes = total_seconds // 60
        cdef uint16_t minute = total_minutes % 60
        cdef uint16_t hour = total_minutes // 60
        cdef object tz_delta = _datetime_mod.timedelta(minutes=ts.tz)
        cdef object tz = _datetime_mod.timezone(tz_delta)
        cdef object utc_dt = _datetime_mod.datetime(d.year, d.month, d.day, hour, minute, second, fraction * 100)
        cdef object local_dt = utc_dt + tz_delta
        return local_dt.replace(tzinfo=tz)

    cdef void _set_timestamp_tz(self, size_t offset, object value):
        """Write a datetime.datetime with tzinfo into the buffer as RDM_PACKED_TIMESTAMPTZ_T.

        Converts local date/time to UTC before storing.
        """
        if not isinstance(value, _datetime_mod.datetime):
            raise TypeError("Expected a datetime.datetime")
        cdef RDM_PACKED_TIMESTAMPTZ_T* ts = <RDM_PACKED_TIMESTAMPTZ_T*>(self.buffer + offset)
        cdef int tz_minutes = 0
        if value.tzinfo is not None:
            tz_minutes = int(value.utcoffset().total_seconds()) // 60
        cdef object utc_dt = value.replace(tzinfo=None) - _datetime_mod.timedelta(minutes=tz_minutes)
        ts.date = <uint32_t>(utc_dt.toordinal())
        ts.time = (<uint32_t>(utc_dt.hour) * 3600 + <uint32_t>(utc_dt.minute) * 60 + <uint32_t>(utc_dt.second)) * 10000 + <uint32_t>(utc_dt.microsecond) // 100
        ts.tz = <int16_t>tz_minutes

    cpdef object _get_field(self, str name):
        """Get the value of a field based on its name and type."""
        cdef dict info = self.__class__._field_info[name]
        cdef int type_ = info['type']
        cdef size_t offset = info['offset']
        cdef bint nullable = info['nullable']
        cdef size_t has_value_offset = info['has_value_offset']
        cdef int array_elements = info['array_elements']
        cdef size_t size = info['size']
        cdef char* start
        cdef char* end
        cdef size_t len_
        cdef uint16_t length
        cdef PyObject *py_dec
        cdef int rc
        cdef bytes py_str

        if not RdmCursor._isAtRow(self):
            raise IndexError("Cursor is not positioned on a valid row")

        if nullable and self.buffer[has_value_offset] == 0:
            return None

        if type_ == BOOLEAN:
            if array_elements > 0:
                return [bool((<uint8_t*>(self.buffer + offset + i))[0]) for i in range(array_elements)]
            return bool((<uint8_t*>(self.buffer + offset))[0])
        elif type_ == UINT8:
            if array_elements > 0:
                return [(<uint8_t*>(self.buffer + offset + i))[0] for i in range(array_elements)]
            return (<uint8_t*>(self.buffer + offset))[0]
        elif type_ == INT8:
            if array_elements > 0:
                return [(<int8_t*>(self.buffer + offset + i))[0] for i in range(array_elements)]
            return (<int8_t*>(self.buffer + offset))[0]
        elif type_ == UINT16:
            if array_elements > 0:
                return [(<uint16_t*>(self.buffer + offset + i*2))[0] for i in range(array_elements)]
            return (<uint16_t*>(self.buffer + offset))[0]
        elif type_ == INT16:
            if array_elements > 0:
                return [(<int16_t*>(self.buffer + offset + i*2))[0] for i in range(array_elements)]
            return (<int16_t*>(self.buffer + offset))[0]
        elif type_ == UINT32:
            if array_elements > 0:
                return [(<uint32_t*>(self.buffer + offset + i*4))[0] for i in range(array_elements)]
            return (<uint32_t*>(self.buffer + offset))[0]
        elif type_ == INT32:
            if array_elements > 0:
                return [(<int32_t*>(self.buffer + offset + i*4))[0] for i in range(array_elements)]
            return (<int32_t*>(self.buffer + offset))[0]
        elif type_ == UINT64:
            if array_elements > 0:
                return [(<uint64_t*>(self.buffer + offset + i*8))[0] for i in range(array_elements)]
            return (<uint64_t*>(self.buffer + offset))[0]
        elif type_ == INT64:
            if array_elements > 0:
                return [(<int64_t*>(self.buffer + offset + i*8))[0] for i in range(array_elements)]
            return (<int64_t*>(self.buffer + offset))[0]
        elif type_ == FLOAT32:
            if array_elements > 0:
                return [(<float*>(self.buffer + offset + i*4))[0] for i in range(array_elements)]
            return (<float*>(self.buffer + offset))[0]
        elif type_ == FLOAT64:
            if array_elements > 0:
                return [(<double*>(self.buffer + offset + i*8))[0] for i in range(array_elements)]
            return (<double*>(self.buffer + offset))[0]
        elif type_ == DECIMAL:
            if array_elements > 0:
                raise ValueError("DECIMAL arrays are not supported")
            py_dec = NULL
            rc = bcd_to_decimal(<const RDM_BCD_T *>(self.buffer + offset), &py_dec)
            if rc != 0:
                raise  ValueError ("Failed to convert to decimal")
            return <object>py_dec
        elif type_ == UUID:
            return self._get_uuid(offset)
        elif type_ == DATE:
            return self._get_date(offset)
        elif type_ == TIME:
            return self._get_time(offset)
        elif type_ == TIME_TZ:
            return self._get_time_tz(offset)
        elif type_ == TIMESTAMP:
            return self._get_timestamp(offset)
        elif type_ == TIMESTAMP_TZ:
            return self._get_timestamp_tz(offset)
        elif type_ == ROWID:
            return False
        elif type_ in [CHAR, VARCHAR]:
            start = self.buffer + offset
            end = <char*>memchr(start, 0, size)
            if end == NULL:
                len_ = size
            else:
                len_ = end - start
            py_str = PyBytes_FromStringAndSize(start, len_)
            return py_str.decode('utf-8')
        elif type_ == BINARY:
            return PyBytes_FromStringAndSize(self.buffer + offset, size)
        elif type_ == VARBINARY:
            length = (<uint16_t*>(self.buffer + offset))[0]
            return PyBytes_FromStringAndSize(self.buffer + offset + 2, length)
        elif type_ in [_BLOB, _CLOB]:
            return True
        else:
            raise ValueError(f"Unsupported type: {type_}")

    def __setattr__(self, name, value):
        # Only allow setting attributes that are defined fields
        if name in self.__class__._field_info:
            self._set_field(name, value)
        else:
            raise AttributeError(f"No such column: {name}")

    def _set_field(self, str name, object value):
        """Set the value of a field based on its name and type."""
        cdef dict info = self.__class__._field_info[name]
        cdef int type_ = info['type']
        cdef size_t offset = info['offset']
        cdef bint nullable = info['nullable']
        cdef size_t has_value_offset = info['has_value_offset']
        cdef int array_elements = info['array_elements']
        cdef size_t size = info['size']
        cdef size_t i
        cdef bytes py_bytes
        cdef size_t length
        cdef int rc

        if not RdmCursor._isAtRow(self):
            raise IndexError("Cursor is not positioned on a valid row")

        self._set_bits |= info['key_bit_position']

        if nullable:
            if value is None:
                self.buffer[has_value_offset] = 0
                return
            self.buffer[has_value_offset] = 1
        else:
            if value is None:
                raise ValueError("Column is not nullable")

        if type_ == BOOLEAN:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<uint8_t*>(self.buffer + offset + i))[0] = <uint8_t>(1 if value[i] else 0)
            else:
                (<uint8_t*>(self.buffer + offset))[0] = <uint8_t>(1 if value else 0)
        elif type_ == UINT8:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<uint8_t*>(self.buffer + offset + i))[0] = <uint8_t>value[i]
            else:
                (<uint8_t*>(self.buffer + offset))[0] = <uint8_t>value
        elif type_ == INT8:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<int8_t*>(self.buffer + offset + i))[0] = <int8_t>value[i]
            else:
                (<int8_t*>(self.buffer + offset))[0] = <int8_t>value
        elif type_ == UINT16:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<uint16_t*>(self.buffer + offset + i*2))[0] = <uint16_t>value[i]
            else:
                (<uint16_t*>(self.buffer + offset))[0] = <uint16_t>value
        elif type_ == INT16:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<int16_t*>(self.buffer + offset + i*2))[0] = <int16_t>value[i]
            else:
                (<int16_t*>(self.buffer + offset))[0] = <int16_t>value
        elif type_ == UINT32:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<uint32_t*>(self.buffer + offset + i*4))[0] = <uint32_t>value[i]
            else:
                (<uint32_t*>(self.buffer + offset))[0] = <uint32_t>value
        elif type_ == INT32:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<int32_t*>(self.buffer + offset + i*4))[0] = <int32_t>value[i]
            else:
                (<int32_t*>(self.buffer + offset))[0] = <int32_t>value
        elif type_ == UINT64:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<uint64_t*>(self.buffer + offset + i*8))[0] = <uint64_t>value[i]
            else:
                (<uint64_t*>(self.buffer + offset))[0] = <uint64_t>value
        elif type_ == INT64:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<int64_t*>(self.buffer + offset + i*8))[0] = <int64_t>value[i]
            else:
                (<int64_t*>(self.buffer + offset))[0] = <int64_t>value
        elif type_ == FLOAT32:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<float*>(self.buffer + offset + i*4))[0] = <float>value[i]
            else:
                (<float*>(self.buffer + offset))[0] = <float>value
        elif type_ == FLOAT64:
            if array_elements > 0:
                if len(value) != array_elements:
                    raise ValueError("Array length mismatch")
                for i from 0 <= i < array_elements:
                    (<double*>(self.buffer + offset + i*8))[0] = <double>value[i]
            else:
                (<double*>(self.buffer + offset))[0] = <double>value
        elif type_ == DECIMAL:
            if array_elements > 0:
                raise ValueError("DECIMAL arrays are not supported")
            rc = decimal_to_bcd(<PyObject *>value, <RDM_BCD_T *>(self.buffer + offset))
            if rc != 0:
                raise ValueError ("Failed to convert to BCD")
        elif type_ == UUID:
            self._set_uuid(offset, value)
        elif type_ == DATE:
            self._set_date(offset, value)
        elif type_ == TIME:
            self._set_time(offset, value)
        elif type_ == TIME_TZ:
            self._set_time_tz(offset, value)
        elif type_ == TIMESTAMP:
            self._set_timestamp(offset, value)
        elif type_ == TIMESTAMP_TZ:
            self._set_timestamp_tz(offset, value)
        elif type_ == ROWID:
            pass  # Only handle nullability for now
        elif type_ in [CHAR, VARCHAR]:
            py_bytes = value.encode('utf-8')
            length = len(py_bytes)
            if length >= size:
                raise ValueError("String exceeds buffer size")
            for i from 0 <= i < length:
                self.buffer[offset + i] = py_bytes[i]
            self.buffer[offset + length] = 0
        elif type_ == BINARY:
            if len(value) != size:
                raise ValueError("Binary size mismatch")
            for i from 0 <= i < size:
                self.buffer[offset + i] = value[i]
        elif type_ == VARBINARY:
            length = len(value)
            if length > size - 2:
                raise ValueError("Varbinary exceeds maximum size")
            (<uint16_t*>(self.buffer + offset))[0] = <uint16_t>length
            for i from 0 <= i < length:
                self.buffer[offset + 2 + i] = value[i]
        elif type_ in [_BLOB, _CLOB]:
            pass  # Only handle nullability for now
        else:
            raise ValueError(f"Unsupported type: {type_}")

def _create_table_class(RdmDb db, table_name, table_id, table_size, columns):
    """Create a Python class for a table with properties for each column."""
    field_info = {}
    for col in columns:
        col['key_bit_position'] = 0
        field_info[col['name']] = col
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(table_name, (StructWrapper,), properties)
    cls.__size__ = table_size
    cls._field_info = field_info
    cls._table_id = table_id
    cls._get_id = classmethod(lambda cls: cls._table_id)
    cls._db = db
    return cls

def _create_udt_class(RdmDb db, udt_name, udt_size, columns):
    """Create a Python class for a user-defined type with properties for each column."""
    field_info = {}
    for col in columns:
        col['key_bit_position'] = 0
        field_info[col['name']] = col
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(udt_name, (StructWrapper,), properties)
    cls.__size__ = udt_size
    cls._field_info = field_info
    cls._db = db
    return cls

def _create_key_class(db, key_name, key_id, key_size, elements):
    """Create a Python class for a key with properties for each element."""
    field_info = {}
    bit = 1
    for elem in elements:
        elem['key_bit_position'] = bit
        field_info[elem['name']] = elem
        bit <<= 1
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(f"{key_name}_Key", (StructWrapper,), properties)
    cls.__size__ = key_size
    cls._field_info = field_info
    cls.key_id = key_id
    cls._get_id = classmethod(lambda cls: cls.key_id)
    cls._db = db
    return cls

cdef _build_classes(RdmDb db):
    """Build classes for all tables and keys in the database."""
    cdef DB_TABLE* db_table = new DB_TABLE()
    cdef TABLE_COLUMN* column = new TABLE_COLUMN()
    cdef TABLE_KEY* key = new TABLE_KEY()
    cdef KEY_ELEMENT* element = new KEY_ELEMENT()
    cdef DB_REFERENCE* reference = new DB_REFERENCE()
    cdef DB_UD_TYPE* ud_type = new DB_UD_TYPE()
    cdef RDM_RETCODE rc

    try:
        db._userDefinedTypes = {}
        ud_type.setDatabase(db.db)
        rc = ud_type.moveToFirst()
        while rc == sOKAY:
            type_name = ud_type.getName().decode('utf-8')
            type_size = ud_type.getSize()
            columns = []

            udt_class = _create_table_class(db, type_name, 0, type_size, columns)
            db._userDefinedTypes[type_name] = udt_class
            rc = ud_type.moveToNext()

        db._tables = {}
        db._keys = {}
        db_table.setDatabase(db.db)
        rc = db_table.moveToFirst()
        while rc == sOKAY:
            table_name = db_table.getName().decode('utf-8')
            table_id = db_table.getId()
            table_size = db_table.getSize()
            columns = []

            column.setTable(db_table)
            rc = column.moveToFirst()
            while rc == sOKAY:
                col_info = {
                    'name': column.getName().decode('utf-8'),
                    'type': column.getType(),
                    'offset': column.getOffset(),
                    'size': column.getSize(),
                    'nullable': column.getNullable(),
                    'has_value_offset': column.getHasValueOffset(),
                    'array_elements': column.getArrayElements(),
                    'string_length': column.getStringLength(),
                }
                columns.append(col_info)
                rc = column.moveToNext()

            table_class = _create_table_class(db, table_name, table_id, table_size, columns)
            db._tables[table_name] = table_class

            key.setTable(db_table)
            rc = key.moveToFirst()
            while rc == sOKAY:
                key_name = key.getName().decode('utf-8')
                key_id = key.getId()
                key_size = key.getSize()
                elements = []

                element.setKey(key)
                rc = element.moveToFirst()
                while rc == sOKAY:
                    elem_info = {
                        'name': element.getName().decode('utf-8'),
                        'type': element.getType(),
                        'offset': element.getOffset(),
                        'size': element.getSize(),
                        'nullable': element.getNullable(),
                        'has_value_offset': element.getHasValueOffset(),
                        'array_elements': element.getArrayElements(),
                        'string_length': element.getStringLength(),
                    }
                    elements.append(elem_info)
                    rc = element.moveToNext()

                key_class = _create_key_class(db, key_name, key_id, key_size, elements)
                db._keys[(table_name, key_name)] = key_class
                rc = key.moveToNext()

            rc = db_table.moveToNext()

        db._references = {}
        reference.setDatabase(db.db)
        rc = reference.moveToFirst()
        while rc == sOKAY:
            ref_name = reference.getName().decode('utf-8')
            ref_id = reference.getId()
            primary_table_name = reference.getPrimaryTableName().decode('utf-8')
            foreign_table_name = reference.getForeignTableName().decode('utf-8')
            primary_class = db._tables[primary_table_name]
            foreign_class = db._tables[foreign_table_name]
            db._references[ref_name] = (ref_id, primary_class, foreign_class)
            rc = reference.moveToNext()

    finally:
        del db_table
        del column
        del key
        del element
        del ud_type
        del reference

cdef dict _rdm_type_names = {
    <int>RDM_TYPE.BOOLEAN: "BOOLEAN",
    <int>RDM_TYPE.UINT8: "UINT8",
    <int>RDM_TYPE.INT8: "INT8",
    <int>RDM_TYPE.UINT16: "UINT16",
    <int>RDM_TYPE.INT16: "INT16",
    <int>RDM_TYPE.UINT32: "UINT32",
    <int>RDM_TYPE.INT32: "INT32",
    <int>RDM_TYPE.UINT64: "UINT64",
    <int>RDM_TYPE.INT64: "INT64",
    <int>RDM_TYPE.FLOAT32: "FLOAT32",
    <int>RDM_TYPE.FLOAT64: "FLOAT64",
    <int>RDM_TYPE.DECIMAL: "DECIMAL",
    <int>RDM_TYPE.DATE: "DATE",
    <int>RDM_TYPE.TIME: "TIME",
    <int>RDM_TYPE.TIME_TZ: "TIME_TZ",
    <int>RDM_TYPE.TIMESTAMP: "TIMESTAMP",
    <int>RDM_TYPE.TIMESTAMP_TZ: "TIMESTAMP_TZ",
    <int>RDM_TYPE.ROWID: "ROWID",
    <int>RDM_TYPE.UUID: "UUID",
    <int>RDM_TYPE.CHAR: "CHAR",
    <int>RDM_TYPE.VARCHAR: "VARCHAR",
    <int>RDM_TYPE.BINARY: "BINARY",
    <int>RDM_TYPE.VARBINARY: "VARBINARY",
    <int>RDM_TYPE._BLOB: "BLOB",
    <int>RDM_TYPE._CLOB: "CLOB",
    <int>RDM_TYPE._UNKNOWN: "UNKNOWN"
}

def _print_indented(int level, str text):
    print("    " * level + text)

cdef _print_database_schema(RdmDb db):
    cdef DB_TABLE* db_table = new DB_TABLE()
    cdef TABLE_COLUMN* column = new TABLE_COLUMN()
    cdef TABLE_KEY* key = new TABLE_KEY()
    cdef KEY_ELEMENT* element = new KEY_ELEMENT()
    cdef RDM_RETCODE rc
    db_table.setDatabase(db.db)
    rc = db_table.moveToFirst()
    while rc == sOKAY:
        _print_indented(0, f"Table: {db_table.getName()} (ID: {db_table.getId()}, Size: {db_table.getSize()})")
        
        # Iterate over columns
        column.setTable(db_table)
        rc = column.moveToFirst()
        while rc == sOKAY:
            _print_indented(1, f"Column: {column.getName()} (ID: {column.getId()}, Type: {_rdm_type_names[<int>column.getType()]}, Offset: {column.getOffset()}, HasValueOffset: {column.getHasValueOffset()}, Size: {column.getSize()}, Nullable: {column.getNullable()}, ArrayElements: {column.getArrayElements()}, StringLength: {column.getStringLength()})")
            rc = column.moveToNext()
        
        # Iterate over keys
        key.setTable(db_table)
        rc = key.moveToFirst()
        while rc == sOKAY:
            _print_indented(1, f"Key: {key.getName()} (ID: {key.getId()}, Size: {key.getSize()})")
            
            # Iterate over key elements
            element.setKey(key)
            rc = element.moveToFirst()
            while rc == sOKAY:
                _print_indented(2, f"Element: {element.getName()} (Type: {_rdm_type_names[<int>element.getType()]}, Offset: {element.getOffset()}, HasValueOffset: {element.getHasValueOffset()}, Size: {element.getSize()}, Nullable: {element.getNullable()}, ArrayElements: {element.getArrayElements()}, StringLength: {element.getStringLength()})")
                rc = element.moveToNext()
            rc = key.moveToNext()
        rc = db_table.moveToNext()

    reference = new DB_REFERENCE()
    reference.setDatabase(db.db)
    rc = reference.moveToFirst()
    while rc == sOKAY:
        ref_name = reference.getName().decode('utf-8')
        ref_id = reference.getId()
        primary_table_name = reference.getPrimaryTableName().decode('utf-8')
        foreign_table_name = reference.getForeignTableName().decode('utf-8')
        _print_indented(0, f"Reference: {ref_name} (ID: {ref_id}), Primary: {primary_table_name}, Foreign: {foreign_table_name}")
        rc = reference.moveToNext()
    del reference

    cdef DB_UD_TYPE* ud_type = new DB_UD_TYPE()
    ud_type.setDatabase(db.db)
    rc = ud_type.moveToFirst()
    while rc == sOKAY:
        _print_indented(0, f"UserDefinedType: {ud_type.getName()} (Size: {ud_type.getSize()})")
        rc = ud_type.moveToNext()
    del ud_type

    del db_table
    del column
    del key
    del element

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
            trans = RdmTrans(self, True, _token)
        return factory.handleCode(rc), trans

    def startRead(self) -> Tuple[Status, RdmTrans]:
        """Start a readtransaction."""
        cdef RdmTrans trans = None
        rc = self._validate()
        if rc == sOKAY:
            trans = RdmTrans(self, False, _token)
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
