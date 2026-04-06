# cython: language_level=3

from libc.stdlib cimport malloc, free
from libc.stdint cimport uint32_t
from .retcodetypes cimport sOKAY, sTRUNCATE, eNOMEMORY, RDM_RETCODE
from .datetimetypes cimport RDM_PACKED_TIMETZ_T, RDM_PACKED_TIME_T, RDM_TIME_FORMAT

cdef extern from "rdmtimetzapi.h":
    RDM_RETCODE rdm_timetzNowAsString(int16_t time_zone, char *timebuf, size_t buflen) nogil
    RDM_RETCODE rdm_timetzFromString(const char *str, RDM_PACKED_TIMETZ_T *ptz) nogil
    RDM_RETCODE rdm_timetzNow(int16_t time_zone, RDM_PACKED_TIMETZ_T *ptz) nogil
    RDM_RETCODE rdm_timetzToTime(RDM_PACKED_TIMETZ_T timetzVal, int16_t tz_disp, RDM_PACKED_TIME_T *pTimeVal) nogil
    RDM_RETCODE rdm_timetzToString(RDM_PACKED_TIMETZ_T timetzVal, RDM_TIME_FORMAT time_fmt, char *buf, size_t bufSize, size_t *puSize) nogil
    RDM_PACKED_TIMETZ_T rdm_timetzZero() nogil

def timetz_now_as_string(int16_t time_zone):
    cdef char timebuf[32]
    cdef RDM_RETCODE ret = rdm_timetzNowAsString(time_zone, timebuf, 32)
    if ret == sOKAY:
        return timebuf.decode('utf-8')
    elif ret == sTRUNCATE:
        raise ValueError("Buffer too small for time string")
    else:
        raise RuntimeError(f"Error code: {ret}")

def timetz_from_string(str s):
    cdef RDM_PACKED_TIMETZ_T tz
    cdef bytes py_bytes = s.encode('utf-8')
    cdef const char* c_str = py_bytes
    cdef RDM_RETCODE ret = rdm_timetzFromString(c_str, &tz)
    if ret == sOKAY:
        return (tz.time, tz.tz)
    else:
        raise RuntimeError(f"Error code: {ret}")

def timetz_now(int16_t time_zone):
    cdef RDM_PACKED_TIMETZ_T tz
    cdef RDM_RETCODE ret = rdm_timetzNow(time_zone, &tz)
    if ret == sOKAY:
        return (tz.time, tz.tz)
    else:
        raise RuntimeError(f"Error code: {ret}")

def timetz_to_time(uint32_t time, int16_t tz, int16_t tz_disp):
    cdef RDM_PACKED_TIMETZ_T timetz
    timetz.time = time
    timetz.tz = tz
    cdef RDM_PACKED_TIME_T time_val
    cdef RDM_RETCODE ret = rdm_timetzToTime(timetz, tz_disp, &time_val)
    if ret == sOKAY:
        return time_val
    else:
        raise RuntimeError(f"Error code: {ret}")

def timetz_to_string(uint32_t time, int16_t tz, RDM_TIME_FORMAT time_fmt):
    cdef RDM_PACKED_TIMETZ_T timetz
    timetz.time = time
    timetz.tz = tz
    cdef size_t required_size
    cdef RDM_RETCODE ret = rdm_timetzToString(timetz, time_fmt, NULL, 0, &required_size)
    if ret != sOKAY and ret != sTRUNCATE:
        raise RuntimeError(f"Error code: {ret}")
    cdef char* buf = <char*>malloc(required_size)
    if buf == NULL:
        raise MemoryError()
    try:
        ret = rdm_timetzToString(timetz, time_fmt, buf, required_size, NULL)
        if ret == sOKAY:
            return buf.decode('utf-8')
        else:
            raise RuntimeError(f"Error code: {ret}")
    finally:
        free(buf)

def timetz_zero():
    cdef RDM_PACKED_TIMETZ_T tz = rdm_timetzZero()
    return (tz.time, tz.tz)
