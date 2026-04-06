# cython: language_level=3

from libc.stdint cimport int16_t
from libc.stddef cimport size_t
from .datetimetypes cimport RDM_PACKED_TIMETZ_T, RDM_PACKED_TIME_T, RDM_TIME_FORMAT
from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmtimetzapi.h":
    RDM_RETCODE rdm_timetzNowAsString(int16_t time_zone, char *timebuf, size_t buflen) nogil
    RDM_RETCODE rdm_timetzFromString(const char *str, RDM_PACKED_TIMETZ_T *ptz) nogil
    RDM_RETCODE rdm_timetzNow(int16_t time_zone, RDM_PACKED_TIMETZ_T *ptz) nogil
    RDM_RETCODE rdm_timetzToTime(RDM_PACKED_TIMETZ_T timetzVal, int16_t tz_disp, RDM_PACKED_TIME_T *pTimeVal) nogil
    RDM_RETCODE rdm_timetzToString(RDM_PACKED_TIMETZ_T timetzVal, RDM_TIME_FORMAT time_fmt, char *buf, size_t bufSize, size_t *puSize) nogil
    RDM_PACKED_TIMETZ_T rdm_timetzZero() nogil
