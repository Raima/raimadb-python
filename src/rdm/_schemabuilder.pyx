# cython: language_level=3

from .types cimport RDM_DB, RDM_TABLE_ID, RDM_COLUMN_ID, RDM_KEY_ID, RDM_REF_ID
from .retcodetypes cimport RDM_RETCODE, sOKAY
from libc.stdint cimport uint16_t, uint32_t

from ._structwrapper import StructWrapper
from .dbapi cimport RdmDb

cdef extern from "table_column.h" namespace "RDM::RUNTIME":
    cdef enum RDM_TYPE:
        BOOLEAN = 0
        UINT8
        INT8
        UINT16
        INT16
        UINT32
        INT32
        UINT64
        INT64
        FLOAT32
        FLOAT64
        DECIMAL
        DATE
        TIME
        TIME_TZ
        TIMESTAMP
        TIMESTAMP_TZ
        ROWID
        UUID
        CHAR
        VARCHAR
        BINARY
        VARBINARY
        _BLOB
        _CLOB
        _UNKNOWN

cdef extern from "db_table.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_TABLE:
        DB_TABLE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_TABLE_ID getId() nogil
        uint32_t getSize() nogil

cdef extern from "table_column.h" namespace "RDM::RUNTIME":
    cdef cppclass TABLE_COLUMN:
        TABLE_COLUMN()
        void setTable(const DB_TABLE* table) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_COLUMN_ID getId() nogil
        RDM_TYPE getType() nogil
        uint32_t getOffset() nogil
        uint32_t getHasValueOffset() nogil
        bint getNullable() nogil
        uint32_t getSize() nogil
        uint16_t getArrayElements() nogil
        uint32_t getStringLength() nogil

cdef extern from "table_key.h" namespace "RDM::RUNTIME":
    cdef cppclass TABLE_KEY:
        TABLE_KEY()
        void setTable(const DB_TABLE* table) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_KEY_ID getId() nogil
        uint32_t getSize() nogil

cdef extern from "key_element.h" namespace "RDM::RUNTIME":
    cdef cppclass KEY_ELEMENT:
        KEY_ELEMENT()
        void setKey(const TABLE_KEY* key) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_TYPE getType() nogil
        uint32_t getOffset() nogil
        uint32_t getHasValueOffset() nogil
        bint getNullable() nogil
        uint32_t getSize() nogil
        uint16_t getArrayElements() nogil
        uint32_t getStringLength() nogil

cdef extern from "db_reference.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_REFERENCE:
        DB_REFERENCE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        RDM_REF_ID getId() nogil
        const char* getPrimaryTableName() nogil
        const char* getForeignTableName() nogil
        RDM_TABLE_ID getPrimaryTableId() nogil
        RDM_TABLE_ID getForeignTableId() nogil

cdef extern from "db_ud_type.h" namespace "RDM::RUNTIME":
    cdef cppclass DB_UD_TYPE:
        DB_UD_TYPE()
        void setDatabase(RDM_DB db) nogil
        RDM_RETCODE moveToFirst() nogil
        RDM_RETCODE moveToNext() nogil
        const char* getName() nogil
        uint32_t getSize() nogil


def _create_table_class(db, table_name, table_id, table_size, columns):
    """Create a Python class for a table with properties for each column."""
    field_info = {}
    for col in columns:
        col['key_bit_position'] = 0
        field_info[col['name']] = col
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(table_name, (StructWrapper,), properties)
    cls.__size__ = table_size
    cls._field_info = field_info
    cls._table_id = table_id
    cls._get_id = classmethod(lambda cls: cls._table_id)
    cls._db = db
    return cls

def _create_udt_class(db, udt_name, udt_size, columns):
    """Create a Python class for a user-defined type with properties for each column."""
    field_info = {}
    for col in columns:
        col['key_bit_position'] = 0
        field_info[col['name']] = col
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(udt_name, (StructWrapper,), properties)
    cls.__size__ = udt_size
    cls._field_info = field_info
    cls._db = db
    return cls

def _create_key_class(db, key_name, key_id, key_size, elements):
    """Create a Python class for a key with properties for each element."""
    field_info = {}
    bit = 1
    for elem in elements:
        elem['key_bit_position'] = bit
        field_info[elem['name']] = elem
        bit <<= 1
    properties = {}
    for name in field_info:
        properties[name] = property(
            lambda self, n=name: self._get_field(n),
            lambda self, v, n=name: self._set_field(n, v)
        )
    cls = type(f"{key_name}_Key", (StructWrapper,), properties)
    cls.__size__ = key_size
    cls._field_info = field_info
    cls.key_id = key_id
    cls._get_id = classmethod(lambda cls: cls.key_id)
    cls._db = db
    return cls

def _build_classes(RdmDb db):
    """Build classes for all tables and keys in the database."""
    cdef DB_TABLE* db_table = new DB_TABLE()
    cdef TABLE_COLUMN* column = new TABLE_COLUMN()
    cdef TABLE_KEY* key = new TABLE_KEY()
    cdef KEY_ELEMENT* element = new KEY_ELEMENT()
    cdef DB_REFERENCE* reference = new DB_REFERENCE()
    cdef DB_UD_TYPE* ud_type = new DB_UD_TYPE()
    cdef RDM_RETCODE rc

    try:
        db._userDefinedTypes = {}
        ud_type.setDatabase(db.db)
        rc = ud_type.moveToFirst()
        while rc == sOKAY:
            type_name = ud_type.getName().decode('utf-8')
            type_size = ud_type.getSize()
            columns = []

            udt_class = _create_table_class(db, type_name, 0, type_size, columns)
            db._userDefinedTypes[type_name] = udt_class
            rc = ud_type.moveToNext()

        db._tables = {}
        db._keys = {}
        db_table.setDatabase(db.db)
        rc = db_table.moveToFirst()
        while rc == sOKAY:
            table_name = db_table.getName().decode('utf-8')
            table_id = db_table.getId()
            table_size = db_table.getSize()
            columns = []

            column.setTable(db_table)
            rc = column.moveToFirst()
            while rc == sOKAY:
                col_info = {
                    'name': column.getName().decode('utf-8'),
                    'type': column.getType(),
                    'offset': column.getOffset(),
                    'size': column.getSize(),
                    'nullable': column.getNullable(),
                    'has_value_offset': column.getHasValueOffset(),
                    'array_elements': column.getArrayElements(),
                    'string_length': column.getStringLength(),
                }
                columns.append(col_info)
                rc = column.moveToNext()

            table_class = _create_table_class(db, table_name, table_id, table_size, columns)
            db._tables[table_name] = table_class

            key.setTable(db_table)
            rc = key.moveToFirst()
            while rc == sOKAY:
                key_name = key.getName().decode('utf-8')
                key_id = key.getId()
                key_size = key.getSize()
                elements = []

                element.setKey(key)
                rc = element.moveToFirst()
                while rc == sOKAY:
                    elem_info = {
                        'name': element.getName().decode('utf-8'),
                        'type': element.getType(),
                        'offset': element.getOffset(),
                        'size': element.getSize(),
                        'nullable': element.getNullable(),
                        'has_value_offset': element.getHasValueOffset(),
                        'array_elements': element.getArrayElements(),
                        'string_length': element.getStringLength(),
                    }
                    elements.append(elem_info)
                    rc = element.moveToNext()

                key_class = _create_key_class(db, key_name, key_id, key_size, elements)
                db._keys[(table_name, key_name)] = key_class
                rc = key.moveToNext()

            rc = db_table.moveToNext()

        db._references = {}
        reference.setDatabase(db.db)
        rc = reference.moveToFirst()
        while rc == sOKAY:
            ref_name = reference.getName().decode('utf-8')
            ref_id = reference.getId()
            primary_table_name = reference.getPrimaryTableName().decode('utf-8')
            foreign_table_name = reference.getForeignTableName().decode('utf-8')
            primary_class = db._tables[primary_table_name]
            foreign_class = db._tables[foreign_table_name]
            db._references[ref_name] = (ref_id, primary_class, foreign_class)
            rc = reference.moveToNext()

    finally:
        del db_table
        del column
        del key
        del element
        del ud_type
        del reference

cdef dict _rdm_type_names = {
    <int>RDM_TYPE.BOOLEAN: "BOOLEAN",
    <int>RDM_TYPE.UINT8: "UINT8",
    <int>RDM_TYPE.INT8: "INT8",
    <int>RDM_TYPE.UINT16: "UINT16",
    <int>RDM_TYPE.INT16: "INT16",
    <int>RDM_TYPE.UINT32: "UINT32",
    <int>RDM_TYPE.INT32: "INT32",
    <int>RDM_TYPE.UINT64: "UINT64",
    <int>RDM_TYPE.INT64: "INT64",
    <int>RDM_TYPE.FLOAT32: "FLOAT32",
    <int>RDM_TYPE.FLOAT64: "FLOAT64",
    <int>RDM_TYPE.DECIMAL: "DECIMAL",
    <int>RDM_TYPE.DATE: "DATE",
    <int>RDM_TYPE.TIME: "TIME",
    <int>RDM_TYPE.TIME_TZ: "TIME_TZ",
    <int>RDM_TYPE.TIMESTAMP: "TIMESTAMP",
    <int>RDM_TYPE.TIMESTAMP_TZ: "TIMESTAMP_TZ",
    <int>RDM_TYPE.ROWID: "ROWID",
    <int>RDM_TYPE.UUID: "UUID",
    <int>RDM_TYPE.CHAR: "CHAR",
    <int>RDM_TYPE.VARCHAR: "VARCHAR",
    <int>RDM_TYPE.BINARY: "BINARY",
    <int>RDM_TYPE.VARBINARY: "VARBINARY",
    <int>RDM_TYPE._BLOB: "BLOB",
    <int>RDM_TYPE._CLOB: "CLOB",
    <int>RDM_TYPE._UNKNOWN: "UNKNOWN"
}

def _print_indented(int level, str text):
    print("    " * level + text)

def _print_database_schema(RdmDb db):
    cdef DB_TABLE* db_table = new DB_TABLE()
    cdef TABLE_COLUMN* column = new TABLE_COLUMN()
    cdef TABLE_KEY* key = new TABLE_KEY()
    cdef KEY_ELEMENT* element = new KEY_ELEMENT()
    cdef RDM_RETCODE rc
    db_table.setDatabase(db.db)
    rc = db_table.moveToFirst()
    while rc == sOKAY:
        _print_indented(0, f"Table: {db_table.getName()} (ID: {db_table.getId()}, Size: {db_table.getSize()})")

        # Iterate over columns
        column.setTable(db_table)
        rc = column.moveToFirst()
        while rc == sOKAY:
            _print_indented(1, f"Column: {column.getName()} (ID: {column.getId()}, Type: {_rdm_type_names[<int>column.getType()]}, Offset: {column.getOffset()}, HasValueOffset: {column.getHasValueOffset()}, Size: {column.getSize()}, Nullable: {column.getNullable()}, ArrayElements: {column.getArrayElements()}, StringLength: {column.getStringLength()})")
            rc = column.moveToNext()

        # Iterate over keys
        key.setTable(db_table)
        rc = key.moveToFirst()
        while rc == sOKAY:
            _print_indented(1, f"Key: {key.getName()} (ID: {key.getId()}, Size: {key.getSize()})")

            # Iterate over key elements
            element.setKey(key)
            rc = element.moveToFirst()
            while rc == sOKAY:
                _print_indented(2, f"Element: {element.getName()} (Type: {_rdm_type_names[<int>element.getType()]}, Offset: {element.getOffset()}, HasValueOffset: {element.getHasValueOffset()}, Size: {element.getSize()}, Nullable: {element.getNullable()}, ArrayElements: {element.getArrayElements()}, StringLength: {element.getStringLength()})")
                rc = element.moveToNext()
            rc = key.moveToNext()
        rc = db_table.moveToNext()

    reference = new DB_REFERENCE()
    reference.setDatabase(db.db)
    rc = reference.moveToFirst()
    while rc == sOKAY:
        ref_name = reference.getName().decode('utf-8')
        ref_id = reference.getId()
        primary_table_name = reference.getPrimaryTableName().decode('utf-8')
        foreign_table_name = reference.getForeignTableName().decode('utf-8')
        _print_indented(0, f"Reference: {ref_name} (ID: {ref_id}), Primary: {primary_table_name}, Foreign: {foreign_table_name}")
        rc = reference.moveToNext()
    del reference

    cdef DB_UD_TYPE* ud_type = new DB_UD_TYPE()
    ud_type.setDatabase(db.db)
    rc = ud_type.moveToFirst()
    while rc == sOKAY:
        _print_indented(0, f"UserDefinedType: {ud_type.getName()} (Size: {ud_type.getSize()})")
        rc = ud_type.moveToNext()
    del ud_type

    del db_table
    del column
    del key
    del element
