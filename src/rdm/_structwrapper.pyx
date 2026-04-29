# cython: language_level=3

from .types cimport RDM_CURSOR
from .retcodetypes cimport RDM_RETCODE, sOKAY
from .validate cimport _ValidateDb, _ValidateCursor, _token
from .cursorapi cimport RdmCursor
from libc.stdint cimport uint8_t, int8_t, uint16_t, int16_t, uint32_t, int32_t, uint64_t, int64_t, intptr_t

from cpython.object cimport PyObject
from cpython.bytes cimport PyBytes_FromStringAndSize

from libc.stdlib cimport malloc, free
from libc.string cimport memset, memchr

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

cdef extern from "<arpa/inet.h>" nogil:
    uint32_t ntohl(uint32_t netlong)
    uint16_t ntohs(uint16_t netshort)
    uint32_t htonl(uint32_t hostlong)
    uint16_t htons(uint16_t hostshort)

cdef class StructWrapper(RdmCursor):

    def __init__(self):
        """Initialize the buffer with the class-specific size."""
        cdef _ValidateDb db = self.__class__._db
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
            return (<uint64_t*>(self.buffer + offset))[0]
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
            if array_elements > 0:
                raise ValueError("ROWID does not support arrays")
            if not isinstance(value, int):
                raise TypeError("Expected an integer for ROWID")
            (<uint64_t*>(self.buffer + offset))[0] = value
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
