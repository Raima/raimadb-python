# cython: language_level=3

from libc.stdint cimport uint32_t, uint8_t, uint16_t, uint64_t, uintptr_t, intptr_t
from libc.stddef cimport size_t
from .psptypes cimport RDM_LT, RDM_EQ, RDM_GT
from .retcodetypes cimport RDM_RETCODE

cdef extern from "rdmtypes.h":
    ctypedef struct RDM_DB_S
    ctypedef RDM_DB_S* RDM_DB

    ctypedef struct RDM_CURSOR_S
    ctypedef RDM_CURSOR_S* RDM_CURSOR
    ctypedef const RDM_CURSOR_S* RDM_CURSOR_C

    ctypedef struct RDM_TRANS_S
    ctypedef RDM_TRANS_S* RDM_TRANS

    ctypedef struct RDM_ENCRYPT_S
    ctypedef RDM_ENCRYPT_S* RDM_ENCRYPT
    ctypedef const RDM_ENCRYPT_S* RDM_ENCRYPT_C

    ctypedef uint32_t RDM_TABLE_ID
    ctypedef uint32_t RDM_COLUMN_ID
    ctypedef uint32_t RDM_KEY_ID
    ctypedef uint32_t RDM_REF_ID
    ctypedef uint64_t RDM_TX
    ctypedef uint8_t RDM_HAS_VALUE_T

    cdef enum RDM_RTREE_TYPE:
        RDM_RTREE_ALL
        RDM_RTREE_EXACT
        RDM_RTREE_OVERLAP
        RDM_RTREE_CONTAINS
        RDM_RTREE_NEAREST
        RDM_RTREE_RADIUS_OVERLAP
        RDM_RTREE_RADIUS_CONTAINS
        RDM_RTREE_POLYGON_OVERLAP
        RDM_RTREE_POLYGON_CONTAINS

    cdef enum RDM_RANGE:
        RDM_RANGE_OPEN
        RDM_RANGE_CLOSED

    cdef enum RDM_TRANS_STATUS:
        RDM_TRANS_READ
        RDM_TRANS_UPDATE
        RDM_TRANS_SNAPSHOT
        RDM_TRANS_NONE

    cdef enum RDM_TRANS_PRECOMMIT_STATUS:
        RDM_TRANS_NOT_PRECOMMITTED
        RDM_TRANS_PRECOMMITTED
        RDM_TRANS_PRECOMMITTED_NO_UPDATES

    cdef enum RDM_USER_STATUS:
        RDM_U_EMPTY
        RDM_U_LIVE

    cdef enum RDM_LOCK_STATUS:
        RDM_LOCK_FREE
        RDM_LOCK_READ
        RDM_LOCK_WRITE
        RDM_LOCK_SNAPSHOT
        RDM_LOCK_CATALOG

    cdef enum RDM_CURSOR_STATUS:
        CURSOR_NOT_AT_ROW
        CURSOR_AT_ROW
        CURSOR_BETWEEN
        CURSOR_BEFORE_FIRST
        CURSOR_AFTER_LAST
        CURSOR_DELETED
        CURSOR_CHANGED
        CURSOR_UNLINKED
        CURSOR_ROW_GONE
        CURSOR_SET_GONE
        CURSOR_DROPPED
        CURSOR_NON_DETERMINISTIC

    ctypedef enum RDM_OPEN_MODE:
        RDM_OPEN_SHARED
        RDM_OPEN_EXCLUSIVE
        RDM_OPEN_READONLY
        RDM_OPEN_SHARED_LOCAL
        RDM_OPEN_EXCLUSIVE_LOCAL
        RDM_OPEN_REPLICATE_SOURCE
        RDM_OPEN_REPLICATE_TARGET

    cdef enum RDM_CURSOR_TYPE:
        CURSOR_TYPE_UNKNOWN
        CURSOR_TYPE_BEFORE_FIRST
        CURSOR_TYPE_AFTER_LAST
        CURSOR_TYPE_REC_SCAN
        CURSOR_TYPE_KEY_SCAN
        CURSOR_TYPE_KEY_RANGE
        CURSOR_TYPE_PRIKEY_SCAN
        CURSOR_TYPE_PRIKEY_RANGE
        CURSOR_TYPE_RTREE_SCAN
        CURSOR_TYPE_SET_SCAN
        CURSOR_TYPE_SINGLETON
        CURSOR_TYPE_SYSCOLUMN

    ctypedef enum RDM_ENC_TYPE:
        RDM_ENC_NONE
        RDM_ENC_XOR
        RDM_ENC_AES128
        RDM_ENC_AES192
        RDM_ENC_AES256
        RDM_ENC_DEFAULT

    cdef enum RDM_TRIGGERS_STATUS:
        RDM_TRIGGERS_ON
        RDM_TRIGGERS_OFF
        RDM_TRIGGERS_UNDEFINED

    cdef struct RDM_SEARCH_KEY_S:
        const void* value
        size_t bytesIn
        uint16_t numKeyCols
        uint16_t stringLen
    ctypedef RDM_SEARCH_KEY_S RDM_SEARCH_KEY

    cdef union RDM_RTREE_FILTER:
        uint32_t maxNeighbors
        uint8_t numVertices
        double radius

    cdef struct RDM_RTREE_KEY:
        const void* value
        size_t bytesIn
        RDM_RTREE_TYPE type
        RDM_RTREE_FILTER filter

    cdef struct RDM_RANGE_KEY:
        const void* value
        size_t bytesIn
        uint16_t numKeyCols
        RDM_RANGE range

    cdef struct RDM_ROW_STATUS_INFO:
        RDM_RETCODE rc
        uint32_t index

    cdef struct RDM_COLUMN_INFO:
        char name[509]  # RDM_IDENTIFIER_LEN * 4 + 1 = 127 * 4 + 1
        RDM_COLUMN_ID id

    cdef struct RDM_COLUMN_VALUE:
        void* value
        size_t valueSize

    # Constants
    cdef int RDM_IDENTIFIER_LEN = 127
    cdef RDM_TABLE_ID TABLE_SCHEMA = 0x10002
    cdef int RDM_NO_MORE_TABLES_VAL = 0
    cdef int RDM_LOCK_NONE_VAL = -1
    cdef int RDM_LOCK_ALL_VAL = -2
    cdef int RDM_LOCK_SCHEMA_VAL = -3
    cdef int RDM_LOCK_DB_OPEN_VAL = -4
    cdef RDM_HAS_VALUE_T RDM_COL_HAS_VALUE = 1
    cdef RDM_HAS_VALUE_T RDM_COL_IS_NULL = 0
    cdef RDM_HAS_VALUE_T RDM_COL_STATUS_UNKNOWN = 2
    cdef size_t RDM_ALL_DATA = -1
    cdef RDM_REF_ID REF_CURSOR = 0
    cdef const RDM_TABLE_ID *RDM_LOCK_NONE = <const RDM_TABLE_ID *> <intptr_t> RDM_LOCK_NONE_VAL
    cdef const RDM_TABLE_ID *RDM_LOCK_ALL = <const RDM_TABLE_ID *> <intptr_t> RDM_LOCK_ALL_VAL
    cdef const RDM_TABLE_ID *RDM_LOCK_SCHEMA = <const RDM_TABLE_ID *> <intptr_t> RDM_LOCK_SCHEMA_VAL

    # Function pointer types
    ctypedef RDM_RETCODE (*RDM_REBUILD_INDEX_REPORT_FCN)(const char* table, const char* indexes, uint64_t current, uint64_t total)
    ctypedef void (*RDM_ERROR_FCN)(RDM_DB, RDM_RETCODE, const char*, void*)
#    ctypedef void (*RDM_ERROR_A_FCN)(RDM_DB, RDM_RETCODE, const char*, void*)
#    ctypedef void (*RDM_ERROR_W_FCN)(RDM_DB, RDM_RETCODE, const wchar_t*, void*)