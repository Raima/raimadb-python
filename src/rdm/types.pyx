# cython: language_level=3
from enum import IntEnum
from .types cimport RDM_OPEN_MODE

class OpenMode(IntEnum):
    SHARED = <int>RDM_OPEN_SHARED
    EXCLUSIVE = <int>RDM_OPEN_EXCLUSIVE
    READONLY = <int>RDM_OPEN_READONLY
    SHARED_LOCAL = <int>RDM_OPEN_SHARED_LOCAL
    EXCLUSIVE_LOCAL = <int>RDM_OPEN_EXCLUSIVE_LOCAL
    REPLICATE_SOURCE = <int>RDM_OPEN_REPLICATE_SOURCE
    REPLICATE_TARGET = <int>RDM_OPEN_REPLICATE_TARGET

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