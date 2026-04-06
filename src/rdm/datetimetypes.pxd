# cython: language_level=3

from libc.stdint cimport int16_t, int32_t, uint16_t, uint32_t

cdef extern from "rdmdatetimetypes.h":
    ctypedef char RDM_DATE_SEPARATOR

    ctypedef struct RDM_DATE_T:
        int32_t year
        uint16_t month
        uint16_t day

    ctypedef struct RDM_TIME_T:
        uint16_t hour
        uint16_t minute
        uint16_t second
        uint16_t fraction

    ctypedef struct RDM_TIMESTAMP_T:
        int32_t year
        uint16_t month
        uint16_t day
        uint16_t hour
        uint16_t minute
        uint16_t second
        uint16_t fraction

    ctypedef struct RDM_TIMETZ_T:
        uint16_t hour
        uint16_t minute
        uint16_t second
        uint16_t fraction
        int16_t tz

    ctypedef struct RDM_TIMESTAMPTZ_T:
        int32_t year
        uint16_t month
        uint16_t day
        uint16_t hour
        uint16_t minute
        uint16_t second
        uint16_t fraction
        int16_t tz

    ctypedef uint32_t RDM_PACKED_DATE_T
    ctypedef uint32_t RDM_PACKED_TIME_T

    ctypedef struct RDM_PACKED_TIMESTAMP_T:
        RDM_PACKED_DATE_T date
        RDM_PACKED_TIME_T time

    ctypedef struct RDM_PACKED_TIMETZ_T:
        RDM_PACKED_TIME_T time
        int16_t tz

    ctypedef struct RDM_PACKED_TIMESTAMPTZ_T:
        RDM_PACKED_DATE_T date
        RDM_PACKED_TIME_T time
        int16_t tz

    ctypedef enum RDM_DATE_FORMAT:
        RDM_MMDDYYYY = 1
        RDM_YYYYMMDD
        RDM_DDMMYYYY

    ctypedef enum RDM_TIME_FORMAT:
        RDM_HH = 1
        RDM_HHMM
        RDM_HHMMSS
        RDM_HHMMSSF
        RDM_HHMMSSFF
        RDM_HHMMSSFFF
        RDM_HHMMSSFFFF

    # Macro constants
    cdef uint32_t RDM_DATE_MAX
    cdef uint32_t RDM_TIME_MAX
    cdef int MAX_TIME_PREC
    cdef RDM_DATE_FORMAT RDM_DEF_DATE_FORMAT
    cdef char RDM_DEF_DATE_SEP
    cdef RDM_TIME_FORMAT RDM_DEF_TIME_FORMAT
