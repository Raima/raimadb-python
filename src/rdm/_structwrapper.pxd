# cython: language_level=3

from libc.stdint cimport uint32_t
from .cursorapi cimport RdmCursor

cdef class StructWrapper(RdmCursor):
    cdef char* buffer
    cdef size_t size
    cdef uint32_t _set_bits
    cpdef tuple _get_buffer_address_and_size(self)
    cpdef _get_buffer(self)
    cpdef _get_size(self)
    cpdef object _get_field(self, str name)
    cdef object _get_uuid(self, size_t offset)
    cdef void _set_uuid(self, size_t offset, object value)
    cdef object _get_date(self, size_t offset)
    cdef void _set_date(self, size_t offset, object value)
    cdef object _get_time(self, size_t offset)
    cdef void _set_time(self, size_t offset, object value)
    cdef object _get_time_tz(self, size_t offset)
    cdef void _set_time_tz(self, size_t offset, object value)
    cdef object _get_timestamp(self, size_t offset)
    cdef void _set_timestamp(self, size_t offset, object value)
    cdef object _get_timestamp_tz(self, size_t offset)
    cdef void _set_timestamp_tz(self, size_t offset, object value)
