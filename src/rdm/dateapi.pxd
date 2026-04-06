# cython: language_level=3

from libc.stdint cimport int16_t, uint16_t, int32_t
from libc.stddef cimport size_t

from .datetimetypes cimport (
    RDM_PACKED_DATE_T,
    RDM_DATE_FORMAT
)

from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmdateapi.h":
    const char *rdm_dateDayAbr(RDM_PACKED_DATE_T dt) nogil
    const char *rdm_dateDayName(RDM_PACKED_DATE_T dt) nogil
    uint16_t rdm_dateDayOfMonth(RDM_PACKED_DATE_T dt) nogil
    uint16_t rdm_dateDayOfWeek(RDM_PACKED_DATE_T dt) nogil
    uint16_t rdm_dateDayOfYear(RDM_PACKED_DATE_T dt) nogil
    RDM_RETCODE rdm_dateFromString(const char *str, RDM_DATE_FORMAT date_fmt, RDM_PACKED_DATE_T *pdv) nogil
    uint16_t rdm_dateMonth(RDM_PACKED_DATE_T dt) nogil
    const char *rdm_dateMonthAbr(RDM_PACKED_DATE_T dt) nogil
    const char *rdm_dateMonthName(RDM_PACKED_DATE_T dt) nogil
    RDM_RETCODE rdm_dateNowAsString(int16_t time_zone, char *datebuf, size_t buflen) nogil
    uint16_t rdm_dateQuarter(RDM_PACKED_DATE_T dt) nogil
    RDM_RETCODE rdm_dateToday(int16_t time_zone, RDM_PACKED_DATE_T *pdt) nogil
    RDM_RETCODE rdm_dateToString(RDM_PACKED_DATE_T dateVal, RDM_DATE_FORMAT date_fmt, char date_sep, char *buf, size_t bufSize, size_t *puSize) nogil
    uint16_t rdm_dateWeek(RDM_PACKED_DATE_T dt) nogil
    int32_t rdm_dateYear(RDM_PACKED_DATE_T dt) nogil
    RDM_PACKED_DATE_T rdm_dateZero() nogil
