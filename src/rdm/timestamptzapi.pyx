# cython: language_level=3

from libc.stdint cimport int16_t
from libc.stddef cimport size_t

from .datetimetypes cimport (
    RDM_PACKED_TIMESTAMP_T,
    RDM_PACKED_TIMESTAMPTZ_T,
    RDM_DATE_FORMAT,
    RDM_TIME_FORMAT
)

from .retcodetypes cimport RDM_RETCODE, sOKAY, sTRUNCATE

def timestamptz_from_timestamp(RDM_PACKED_TIMESTAMP_T tsVal, int16_t tz):
    cdef RDM_PACKED_TIMESTAMPTZ_T tszVal
    cdef RDM_RETCODE ret = rdm_timestamptzFromTimestamp(tsVal, tz, &tszVal)
    if ret != sOKAY:
        raise ValueError("Error converting timestamp to timestamptz")
    return tszVal

def timestamptz_from_string(str s, RDM_DATE_FORMAT date_fmt):
    cdef RDM_PACKED_TIMESTAMPTZ_T tsz
    cdef bytes bs = s.encode('utf-8')
    cdef const char* c_str = bs
    cdef RDM_RETCODE ret = rdm_timestamptzFromString(c_str, date_fmt, &tsz)
    if ret != sOKAY:
        raise ValueError("Error converting string to timestamptz")
    return tsz

def timestamptz_now(int16_t time_zone):
    cdef RDM_PACKED_TIMESTAMPTZ_T tsz
    cdef RDM_RETCODE ret = rdm_timestamptzNow(time_zone, &tsz)
    if ret != sOKAY:
        raise ValueError("Error getting current timestamptz")
    return tsz

def timestamptz_now_as_string(int16_t time_zone):
    cdef char buf[256]
    cdef RDM_RETCODE ret = rdm_timestamptzNowAsString(time_zone, buf, sizeof(buf))
    if ret == sTRUNCATE:
        raise ValueError("Buffer too small for timestamptz string")
    elif ret != sOKAY:
        raise ValueError("Error getting current timestamptz as string")
    return buf.decode('utf-8')

def timestamptz_to_timestamp(RDM_PACKED_TIMESTAMPTZ_T tstzVal, int16_t tz_disp):
    cdef RDM_PACKED_TIMESTAMP_T tsVal
    cdef RDM_RETCODE ret = rdm_timestamptzToTimestamp(tstzVal, tz_disp, &tsVal)
    if ret != sOKAY:
        raise ValueError("Error converting timestamptz to timestamp")
    return tsVal

def timestamptz_to_string(RDM_PACKED_TIMESTAMPTZ_T tszVal, RDM_DATE_FORMAT date_format, char date_sep, RDM_TIME_FORMAT time_format):
    cdef size_t uSize
    cdef char buf[256]
    cdef RDM_RETCODE ret = rdm_timestamptzToString(tszVal, date_format, date_sep, time_format, buf, sizeof(buf), &uSize)
    if ret == sTRUNCATE:
        raise ValueError("Buffer too small for timestamptz string")
    elif ret != sOKAY:
        raise ValueError("Error converting timestamptz to string")
    return buf[:uSize].decode('utf-8')

def timestamptz_zero():
    return rdm_timestamptzZero()