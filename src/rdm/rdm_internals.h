/*
 * rdm_internals.h - Forward declarations for RDM internal C++ classes
 *
 * These classes are part of librdmrdm but their headers are not included
 * in the RDM installation. The declarations here match the ABI of the
 * installed library and are sufficient for Cython to generate correct
 * C++ code.
 *
 * Copyright (c) 2025 Raima Inc., All rights reserved.
 */

#ifndef RDM_INTERNALS_H_INCLUDED_
#define RDM_INTERNALS_H_INCLUDED_

#include "rdmtypes.h"

namespace RDM {
    namespace RUNTIME {

        enum RDM_TYPE {
            BOOLEAN = 0,
            UINT8,
            INT8,
            UINT16,
            INT16,
            UINT32,
            INT32,
            UINT64,
            INT64,
            FLOAT32,
            FLOAT64,
            DECIMAL,
            DATE,
            TIME,
            TIME_TZ,
            TIMESTAMP,
            TIMESTAMP_TZ,
            ROWID,
            UUID,
            CHAR,
            VARCHAR,
            BINARY,
            VARBINARY,
            _BLOB,
            _CLOB,
            _UNKNOWN
        };

        class DB_TABLE
        {
          public:
            constexpr DB_TABLE (const RDM_DB_S *db = nullptr) noexcept : m_db (db), m_currentTable (nullptr) {}
            void setDatabase (const RDM_DB_S *db) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            RDM_TABLE_ID getId () const noexcept;
            uint32_t getSize () const noexcept;
          private:
            const RDM_DB_S *m_db;
            const void *m_currentTable;
        };

        class TABLE_COLUMN
        {
          public:
            constexpr TABLE_COLUMN () noexcept : m_table (nullptr), m_currentColumn (nullptr) {}
            void setTable (const DB_TABLE *table) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            RDM_COLUMN_ID getId () const noexcept;
            RDM_TYPE getType () const noexcept;
            uint32_t getOffset () const noexcept;
            uint32_t getHasValueOffset () const noexcept;
            bool getNullable () const noexcept;
            uint32_t getSize () const noexcept;
            uint16_t getArrayElements () const noexcept;
            uint16_t getStringLength () const noexcept;
          private:
            const DB_TABLE *m_table;
            const void *m_currentColumn;
        };

        class TABLE_KEY
        {
          public:
            constexpr TABLE_KEY () noexcept : m_table (nullptr), m_currentKey (nullptr) {}
            void setTable (const DB_TABLE *table) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            RDM_KEY_ID getId () const noexcept;
            uint32_t getSize () const noexcept;
          private:
            const DB_TABLE *m_table;
            const void *m_currentKey;
        };

        class KEY_ELEMENT
        {
          public:
            constexpr KEY_ELEMENT () noexcept : m_key (nullptr), m_currentElement (nullptr) {}
            void setKey (const TABLE_KEY *key) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            RDM_TYPE getType () const noexcept;
            uint32_t getOffset () const noexcept;
            uint32_t getHasValueOffset () const noexcept;
            bool getNullable () const noexcept;
            uint32_t getSize () const noexcept;
            uint16_t getArrayElements () const noexcept;
            uint16_t getStringLength () const noexcept;
          private:
            const TABLE_KEY *m_key;
            const void *m_currentElement;
        };

        class DB_REFERENCE
        {
          public:
            constexpr DB_REFERENCE () noexcept : m_db (nullptr), m_currentRef (nullptr) {}
            void setDatabase (const RDM_DB_S *db) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            RDM_REF_ID getId () const noexcept;
            const char *getPrimaryTableName () const noexcept;
            const char *getForeignTableName () const noexcept;
            RDM_TABLE_ID getPrimaryTableId () const noexcept;
            RDM_TABLE_ID getForeignTableId () const noexcept;
          private:
            const RDM_DB_S *m_db;
            const void *m_currentRef;
        };

        class DB_UD_TYPE
        {
          public:
            constexpr DB_UD_TYPE () noexcept : m_db (nullptr), m_currentType (nullptr) {}
            void setDatabase (const RDM_DB_S *db) noexcept;
            RDM_RETCODE moveToFirst () noexcept;
            RDM_RETCODE moveToNext () noexcept;
            const char *getName () const noexcept;
            uint32_t getSize () const noexcept;
          private:
            const RDM_DB_S *m_db;
            const void *m_currentType;
        };

    } // namespace RUNTIME
} // namespace RDM

#endif /* RDM_INTERNALS_H_INCLUDED_ */
