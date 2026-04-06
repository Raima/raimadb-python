# cython: language_level=3

from libc.stdlib cimport malloc, free
from libc.stdint cimport int16_t, uint16_t, int32_t, uint32_t
from libc.stddef cimport size_t
from .datetimetypes cimport RDM_PACKED_TIMESTAMP_T, RDM_DATE_FORMAT, RDM_TIME_FORMAT
from .retcodetypes cimport RDM_RETCODE, sOKAY, sTRUNCATE, eNOMEMORY

cdef extern from "rdmtimestampapi.h":
    const char *rdm_timestampDayAbr(RDM_PACKED_TIMESTAMP_T ts) nogil
    const char *rdm_timestampDayName(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampDayOfMonth(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampDayOfWeek(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampDayOfYear(RDM_PACKED_TIMESTAMP_T ts) nogil
    void rdm_timestampDaysDiff(RDM_PACKED_TIMESTAMP_T start, RDM_PACKED_TIMESTAMP_T end, uint32_t *diff) nogil
    RDM_RETCODE rdm_timestampFromString(const char *str, RDM_DATE_FORMAT date_fmt, RDM_PACKED_TIMESTAMP_T *ptv) nogil
    uint16_t rdm_timestampHour(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampMinute(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampSecond(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampFraction(RDM_PACKED_TIMESTAMP_T ts) nogil
    uint16_t rdm_timestampMonth(RDM_PACKED_TIMESTAMP_T ts) nogil
    const char *rdm_timestampMonthAbr(RDM_PACKED_TIMESTAMP_T ts) nogil
    const char *rdm_timestampMonthName(RDM_PACKED_TIMESTAMP_T ts) nogil
    RDM_RETCODE rdm_timestampNow(int16_t time_zone, RDM_PACKED_TIMESTAMP_T *ts) nogil
    RDM_RETCODE rdm_timestampNowAsString(int16_t time_zone, char *tsbuf, size_t buflen) nogil
    double rdm_timestampNowAsDouble() nogil
    uint16_t rdm_timestampQuarter(RDM_PACKED_TIMESTAMP_T ts) nogil
    RDM_RETCODE rdm_timestampToString(RDM_PACKED_TIMESTAMP_T tmsv, RDM_DATE_FORMAT date_fmt, char date_sep, RDM_TIME_FORMAT time_fmt, char *buf, size_t bufSize, size_t *puSize) nogil
    uint16_t rdm_timestampWeek(RDM_PACKED_TIMESTAMP_T ts) nogil
    int32_t rdm_timestampYear(RDM_PACKED_TIMESTAMP_T ts) nogil
    RDM_PACKED_TIMESTAMP_T rdm_timestampZero() nogil

def timestamp_day_abr(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    cdef const char* result = rdm_timestampDayAbr(c_ts)
    return <str>result.decode('utf-8')

def timestamp_day_name(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    cdef const char* result = rdm_timestampDayName(c_ts)
    return <str>result.decode('utf-8')

def timestamp_day_of_month(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampDayOfMonth(c_ts)

def timestamp_day_of_week(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampDayOfWeek(c_ts)

def timestamp_day_of_year(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampDayOfYear(c_ts)

def timestamp_days_diff(tuple start, tuple end):
    cdef RDM_PACKED_TIMESTAMP_T c_start
    c_start.date = start[0]
    c_start.time = start[1]
    cdef RDM_PACKED_TIMESTAMP_T c_end
    c_end.date = end[0]
    c_end.time = end[1]
    cdef uint32_t diff
    rdm_timestampDaysDiff(c_start, c_end, &diff)
    return diff

def timestamp_from_string(str s, RDM_DATE_FORMAT date_fmt):
    # Store the bytes object in a variable to keep it alive
    cdef bytes py_bytes = s.encode('utf-8')
    # Get a pointer to the bytes data
    cdef const char* c_str = py_bytes
    cdef RDM_PACKED_TIMESTAMP_T ts
    cdef RDM_RETCODE ret = rdm_timestampFromString(c_str, date_fmt, &ts)
    if ret != sOKAY:
        raise RuntimeError(f"Error {ret}")
    return (ts.date, ts.time)

def timestamp_hour(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampHour(c_ts)

def timestamp_minute(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampMinute(c_ts)

def timestamp_second(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampSecond(c_ts)

def timestamp_fraction(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampFraction(c_ts)

def timestamp_month(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampMonth(c_ts)

def timestamp_month_abr(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    cdef const char* result = rdm_timestampMonthAbr(c_ts)
    return <str>result.decode('utf-8')

def timestamp_month_name(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    cdef const char* result = rdm_timestampMonthName(c_ts)
    return <str>result.decode('utf-8')

def timestamp_now(int16_t time_zone):
    cdef RDM_PACKED_TIMESTAMP_T ts
    cdef RDM_RETCODE ret = rdm_timestampNow(time_zone, &ts)
    if ret != sOKAY:
        raise RuntimeError(f"Error {ret}")
    return (ts.date, ts.time)

def timestamp_now_as_string(int16_t time_zone):
    cdef char tsbuf[50]
    cdef size_t buflen = 50
    cdef RDM_RETCODE ret = rdm_timestampNowAsString(time_zone, tsbuf, buflen)
    if ret == sTRUNCATE:
        raise ValueError("Buffer too small")
    elif ret != sOKAY:
        raise RuntimeError(f"Error {ret}")
    return <str>tsbuf.decode('utf-8')

def timestamp_now_as_double():
    return rdm_timestampNowAsDouble()

def timestamp_quarter(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampQuarter(c_ts)

def timestamp_to_string(tuple ts, RDM_DATE_FORMAT date_fmt, char date_sep, RDM_TIME_FORMAT time_fmt):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    cdef size_t required_size
    cdef RDM_RETCODE ret = rdm_timestampToString(c_ts, date_fmt, date_sep, time_fmt, NULL, 0, &required_size)
    if ret != sOKAY and ret != sTRUNCATE:
        raise RuntimeError(f"Error {ret}")
    cdef char* buf = <char*>malloc(required_size * sizeof(char))
    if buf == NULL:
        raise MemoryError()
    try:
        ret = rdm_timestampToString(c_ts, date_fmt, date_sep, time_fmt, buf, required_size, NULL)
        if ret != sOKAY:
            raise RuntimeError(f"Error {ret}")
        result = <str>buf.decode('utf-8')
        return result
    finally:
        free(buf)

def timestamp_week(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampWeek(c_ts)

def timestamp_year(tuple ts):
    cdef RDM_PACKED_TIMESTAMP_T c_ts
    c_ts.date = ts[0]
    c_ts.time = ts[1]
    return rdm_timestampYear(c_ts)

def timestamp_zero():
    cdef RDM_PACKED_TIMESTAMP_T ts = rdm_timestampZero()
    return (ts.date, ts.time)
