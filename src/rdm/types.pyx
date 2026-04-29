# cython: language_level=3
from enum import IntEnum
from .types cimport (
    RDM_OPEN_MODE,
    RDM_CURSOR_STATUS,
    RDM_CURSOR_TYPE,
    RDM_LOCK_STATUS,
)

class OpenMode(IntEnum):
    SHARED = <int>RDM_OPEN_SHARED
    EXCLUSIVE = <int>RDM_OPEN_EXCLUSIVE
    READONLY = <int>RDM_OPEN_READONLY
    SHARED_LOCAL = <int>RDM_OPEN_SHARED_LOCAL
    EXCLUSIVE_LOCAL = <int>RDM_OPEN_EXCLUSIVE_LOCAL
    REPLICATE_SOURCE = <int>RDM_OPEN_REPLICATE_SOURCE
    REPLICATE_TARGET = <int>RDM_OPEN_REPLICATE_TARGET

class CursorStatus(IntEnum):
    NOT_AT_ROW = <int>CURSOR_NOT_AT_ROW
    AT_ROW = <int>CURSOR_AT_ROW
    BETWEEN = <int>CURSOR_BETWEEN
    BEFORE_FIRST = <int>CURSOR_BEFORE_FIRST
    AFTER_LAST = <int>CURSOR_AFTER_LAST
    DELETED = <int>CURSOR_DELETED
    CHANGED = <int>CURSOR_CHANGED
    UNLINKED = <int>CURSOR_UNLINKED
    ROW_GONE = <int>CURSOR_ROW_GONE
    SET_GONE = <int>CURSOR_SET_GONE
    DROPPED = <int>CURSOR_DROPPED
    NON_DETERMINISTIC = <int>CURSOR_NON_DETERMINISTIC

class CursorType(IntEnum):
    UNKNOWN = <int>CURSOR_TYPE_UNKNOWN
    BEFORE_FIRST = <int>CURSOR_TYPE_BEFORE_FIRST
    AFTER_LAST = <int>CURSOR_TYPE_AFTER_LAST
    REC_SCAN = <int>CURSOR_TYPE_REC_SCAN
    KEY_SCAN = <int>CURSOR_TYPE_KEY_SCAN
    KEY_RANGE = <int>CURSOR_TYPE_KEY_RANGE
    PRIKEY_SCAN = <int>CURSOR_TYPE_PRIKEY_SCAN
    PRIKEY_RANGE = <int>CURSOR_TYPE_PRIKEY_RANGE
    RTREE_SCAN = <int>CURSOR_TYPE_RTREE_SCAN
    SET_SCAN = <int>CURSOR_TYPE_SET_SCAN
    SINGLETON = <int>CURSOR_TYPE_SINGLETON
    SYSCOLUMN = <int>CURSOR_TYPE_SYSCOLUMN

class LockStatus(IntEnum):
    FREE = <int>RDM_LOCK_FREE
    READ = <int>RDM_LOCK_READ
    WRITE = <int>RDM_LOCK_WRITE
    SNAPSHOT = <int>RDM_LOCK_SNAPSHOT
    CATALOG = <int>RDM_LOCK_CATALOG

RDM_CATALOG_EMPTY_SCHEMA = b"""{
  "database":{
    "catver":151,
    "dbver":1,
    "encryption":"none",
    "maxdrawers":0,
    "nodrawers":0,
    "nextdrawer":0,
    "nodoms":0,
    "maxdoms":0,
    "maxtabs":32768,
    "notabs":1,
    "nexttab":1,
    "drawers":[
    ],
    "tables":[
    ]
  }
}
"""