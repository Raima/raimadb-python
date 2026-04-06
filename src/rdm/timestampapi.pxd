# cython: language_level=3

from libc.stdint cimport int16_t, uint16_t, int32_t, uint32_t
from libc.stddef cimport size_t
from .datetimetypes cimport RDM_PACKED_TIMESTAMP_T, RDM_DATE_FORMAT, RDM_TIME_FORMAT
from .retcodetypes cimport RDM_RETCODE

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
