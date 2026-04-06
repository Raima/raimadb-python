# cython: language_level=3

from libc.stdint cimport int16_t, uint16_t, int32_t
from libc.stddef cimport size_t

from .datetimetypes cimport (
    RDM_PACKED_DATE_T,
    RDM_DATE_FORMAT
)

from .retcodetypes cimport RDM_RETCODE, sOKAY, sTRUNCATE

from . cimport dateapi

def date_day_abr(RDM_PACKED_DATE_T dt):
    cdef const char* result = dateapi.rdm_dateDayAbr(dt)
    return (<bytes>result).decode('utf-8')

def date_day_name(RDM_PACKED_DATE_T dt):
    cdef const char* result = dateapi.rdm_dateDayName(dt)
    return (<bytes>result).decode('utf-8')

def date_day_of_month(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateDayOfMonth(dt)

def date_day_of_week(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateDayOfWeek(dt)

def date_day_of_year(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateDayOfYear(dt)

def date_from_string(str s, RDM_DATE_FORMAT date_fmt):
    cdef RDM_PACKED_DATE_T dv
    cdef bytes bs = s.encode('utf-8')
    cdef const char* c_str = bs
    cdef RDM_RETCODE ret = dateapi.rdm_dateFromString(c_str, date_fmt, &dv)
    if ret != sOKAY:
        raise ValueError("Invalid date string")
    return dv

def date_month(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateMonth(dt)

def date_month_abr(RDM_PACKED_DATE_T dt):
    cdef const char* result = dateapi.rdm_dateMonthAbr(dt)
    return (<bytes>result).decode('utf-8')

def date_month_name(RDM_PACKED_DATE_T dt):
    cdef const char* result = dateapi.rdm_dateMonthName(dt)
    return (<bytes>result).decode('utf-8')

def date_now_as_string(int16_t time_zone):
    cdef char buf[256]
    cdef RDM_RETCODE ret = dateapi.rdm_dateNowAsString(time_zone, buf, sizeof(buf))
    if ret == sTRUNCATE:
        raise ValueError("Buffer too small for date string")
    elif ret != sOKAY:
        raise ValueError("Error getting current date as string")
    return buf.decode('utf-8')

def date_quarter(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateQuarter(dt)

def date_today(int16_t time_zone):
    cdef RDM_PACKED_DATE_T dt
    cdef RDM_RETCODE ret = dateapi.rdm_dateToday(time_zone, &dt)
    if ret != sOKAY:
        raise ValueError("Error getting current date")
    return dt

def date_to_string(RDM_PACKED_DATE_T dateVal, RDM_DATE_FORMAT date_fmt, char date_sep):
    cdef size_t uSize
    cdef char buf[256]
    cdef RDM_RETCODE ret = dateapi.rdm_dateToString(dateVal, date_fmt, date_sep, buf, sizeof(buf), &uSize)
    if ret == sTRUNCATE:
        raise ValueError("Buffer too small for date string")
    elif ret != sOKAY:
        raise ValueError("Error converting date to string")
    return buf[:uSize].decode('utf-8')

def date_week(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateWeek(dt)

def date_year(RDM_PACKED_DATE_T dt):
    return dateapi.rdm_dateYear(dt)

def date_zero():
    return dateapi.rdm_dateZero()