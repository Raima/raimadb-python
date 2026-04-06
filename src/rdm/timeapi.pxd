# cython: language_level=3

from libc.stdint cimport uint64_t, uint16_t, int16_t
from libc.stddef cimport size_t
from .datetimetypes cimport RDM_PACKED_TIME_T, RDM_TIME_FORMAT
from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmtimeapi.h":
    uint64_t rdm_timeMeasureMilliSecs() nogil
    RDM_RETCODE rdm_timeFromString(const char *str, RDM_PACKED_TIME_T *ptm) nogil
    uint16_t rdm_timeHour(RDM_PACKED_TIME_T tm) nogil
    uint16_t rdm_timeMinute(RDM_PACKED_TIME_T tm) nogil
    uint16_t rdm_timeSecond(RDM_PACKED_TIME_T tm) nogil
    uint16_t rdm_timeFraction(RDM_PACKED_TIME_T tm) nogil
    RDM_RETCODE rdm_timeToString(RDM_PACKED_TIME_T timeVal, RDM_TIME_FORMAT time_fmt, char *buf, size_t bufSize, size_t *puSize) nogil
    RDM_PACKED_TIME_T rdm_timeZero() nogil
    RDM_RETCODE rdm_timeNow(int16_t time_zone, RDM_PACKED_TIME_T *ptm) nogil
    RDM_RETCODE rdm_timeNowAsString(int16_t time_zone, char *timebuf, size_t buflen) nogil
