# cython: language_level=3

from libc.stdint cimport int16_t
from libc.stddef cimport size_t

from .datetimetypes cimport (
    RDM_PACKED_TIMESTAMP_T,
    RDM_PACKED_TIMESTAMPTZ_T,
    RDM_DATE_FORMAT,
    RDM_TIME_FORMAT
)

from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmtimestamptzapi.h":
    RDM_RETCODE rdm_timestamptzFromTimestamp(
        RDM_PACKED_TIMESTAMP_T tsVal,
        int16_t tz,
        RDM_PACKED_TIMESTAMPTZ_T *pTszVal
    ) nogil

    RDM_RETCODE rdm_timestamptzFromString(
        const char *str,
        RDM_DATE_FORMAT date_fmt,
        RDM_PACKED_TIMESTAMPTZ_T *ptsz
    ) nogil

    RDM_RETCODE rdm_timestamptzNow(
        int16_t time_zone,
        RDM_PACKED_TIMESTAMPTZ_T *tsz
    )

    RDM_RETCODE rdm_timestamptzNowAsString(
        int16_t time_zone,
        char *tszbuf,
        size_t buflen
    ) nogil

    RDM_RETCODE rdm_timestamptzToTimestamp(
        RDM_PACKED_TIMESTAMPTZ_T tstzVal,
        int16_t tz_disp,
        RDM_PACKED_TIMESTAMP_T *pTsVal
    ) nogil

    RDM_RETCODE rdm_timestamptzToString(
        RDM_PACKED_TIMESTAMPTZ_T tszVal,
        RDM_DATE_FORMAT date_format,
        char date_sep,
        RDM_TIME_FORMAT time_format,
        char *buf,
        size_t bufSize,
        size_t *puSize
    ) nogil

    RDM_PACKED_TIMESTAMPTZ_T rdm_timestamptzZero() nogil
