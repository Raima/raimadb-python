# cython: language_level=3

from libc.stdlib cimport malloc, free
from .retcodetypes cimport RDM_RETCODE, sOKAY, sTRUNCATE, eNOMEMORY
from .exceptions_factory import factory

cdef enum:
    TIME_BUF_SIZE = 32

# C-only functions (no Python objects in return types)
cdef uint64_t c_timeMeasureMilliSecs():
    return rdm_timeMeasureMilliSecs()

cdef (RDM_RETCODE, RDM_PACKED_TIME_T) c_timeFromString(const char* c_str):
    cdef RDM_PACKED_TIME_T tm
    cdef RDM_RETCODE ret = rdm_timeFromString(c_str, &tm)
    return (ret, tm)

cdef uint16_t c_timeHour(RDM_PACKED_TIME_T tm):
    return rdm_timeHour(tm)

cdef uint16_t c_timeMinute(RDM_PACKED_TIME_T tm):
    return rdm_timeMinute(tm)

cdef uint16_t c_timeSecond(RDM_PACKED_TIME_T tm):
    return rdm_timeSecond(tm)

cdef uint16_t c_timeFraction(RDM_PACKED_TIME_T tm):
    return rdm_timeFraction(tm)

cdef RDM_RETCODE c_timeToString(RDM_PACKED_TIME_T timeVal, RDM_TIME_FORMAT time_fmt, char** buf, size_t* buf_size):
    cdef size_t required_size
    cdef RDM_RETCODE ret = rdm_timeToString(timeVal, time_fmt, NULL, 0, &required_size)
    if ret != sOKAY and ret != sTRUNCATE:
        return ret
    buf[0] = <char*>malloc(required_size)
    if buf[0] == NULL:
        return eNOMEMORY
    ret = rdm_timeToString(timeVal, time_fmt, buf[0], required_size, NULL)
    buf_size[0] = required_size
    return ret

cdef RDM_PACKED_TIME_T c_timeZero():
    return rdm_timeZero()

cdef (RDM_RETCODE, RDM_PACKED_TIME_T) c_timeNow(int16_t time_zone):
    cdef RDM_PACKED_TIME_T tm
    cdef RDM_RETCODE ret = rdm_timeNow(time_zone, &tm)
    return (ret, tm)

cdef RDM_RETCODE c_timeNowAsString(int16_t time_zone, char* timebuf, size_t buflen):
    return rdm_timeNowAsString(time_zone, timebuf, buflen)

# Python wrappers
def timeMeasureMilliSecs():
    return c_timeMeasureMilliSecs()

def timeFromString(str s):
    cdef bytes b = s.encode('utf-8')
    cdef const char* c_str = b
    cdef (RDM_RETCODE, RDM_PACKED_TIME_T) result = c_timeFromString(c_str)
    return result

def timeHour(RDM_PACKED_TIME_T tm):
    return c_timeHour(tm)

def timeMinute(RDM_PACKED_TIME_T tm):
    return c_timeMinute(tm)

def timeSecond(RDM_PACKED_TIME_T tm):
    return c_timeSecond(tm)

def timeFraction(RDM_PACKED_TIME_T tm):
    return c_timeFraction(tm)

def timeToString(RDM_PACKED_TIME_T timeVal, RDM_TIME_FORMAT time_fmt):
    cdef char* buf
    cdef size_t buf_size
    cdef RDM_RETCODE ret = c_timeToString(timeVal, time_fmt, &buf, &buf_size)
    if ret == sOKAY:
        try:
            return buf.decode('utf-8')
        finally:
            free(buf)
    else:
        return ""

def timeZero():
    return c_timeZero()

def timeNow(int16_t time_zone):
    return c_timeNow(time_zone)

def timeNowAsString(int16_t time_zone):
    cdef char timebuf[TIME_BUF_SIZE]
    cdef RDM_RETCODE ret = c_timeNowAsString(time_zone, timebuf, TIME_BUF_SIZE)
    if ret == sOKAY:
        return timebuf.decode('utf-8')
    else:
        return ""
