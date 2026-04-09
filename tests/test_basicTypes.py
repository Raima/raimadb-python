#!/usr/bin/env python3
import sys

from rdm.retcodetypes import Status

import rdm
from rdm import *
from rdm.tfsapi import *
from rdm.dbapi import *
from rdm.cursorapi import *
from rdm.rdmapi import *
from rdm.types import *
from rdm.exceptions import *
from rdm.retcodetypes import *
import unittest
import math
from builtins import ValueError
import numpy as np
import decimal
from decimal import Decimal
import uuid

class TestDataTypes(unittest.TestCase):
    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay, "Failed to initialize TFS")
        try:
            self.tfs.dropDatabase("data_types_test")
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog("""
            create table data_types (
                id int primary key,
                u8 uint8 default 10 not null,
                u16 uint16 default 100,
                u32 uint32 default 1000 not null,
                u64 uint64 default 10000,
                i8 int8 default 50 not null,
                i16 int16 default 500,
                i32 int32 default 5000 not null,
                i64 int64 default 50000,
                f32 float32 default 1.23 not null,
                f64 float64 default 123.45,
                decx decimal(10,2) default 999.99 not null,
                decy decimal(32,10) default null,
                c char default 'A' not null,
                c10 char(10) default 'abcdefghij',
                vc varchar(10) default 'test' not null,
                vc_octet varchar(10 octets) default 'octet' not null,
                uid uuid default null
            );
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog")
        status = self.db.open("data_types_test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
        self.tfs.dropDatabase("data_types_test")
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay, "Failed to free TFS")

    # Helper function for integer types
    def _test_integer_type(self, type_name, min_val, max_val, default_val, not_null=True):
        status, trans = self.db.startUpdate()
        values = [(1, min_val), (2, max_val), (3, min_val - 1), (4, max_val + 1)]
        for id_val, val in values:
            with self.subTest(type=type_name, value=val):
                if val is None or (min_val <= val <= max_val):
                    kwargs = {'ID': id_val, type_name: val}
                    status, row = self.db.insertRow("DATA_TYPES", **kwargs)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(getattr(row, type_name), val)
                else:
                    with self.assertRaises(OverflowError):
                        kwargs = {'ID': id_val, type_name: val}
                        self.db.insertRow("DATA_TYPES", **kwargs)
        if not_null:
            with self.assertRaises(ValueError):
                self.db.insertRow("DATA_TYPES", ID=5, **{type_name: None})
        status, row = self.db.insertRow("DATA_TYPES", ID=6)  # Test default
        self.assertEqual(status, Status.Okay)
        self.assertEqual(getattr(row, type_name), default_val)
        trans.end()

    # Helper function for float types
    def _test_float_type(self, type_name, min_val, max_val, default_val, not_null=True):
        status, trans = self.db.startUpdate()
        values = [(1, min_val), (2, max_val), (3, -math.inf), (4, math.inf)]
        for id_val, val in values:
            with self.subTest(type=type_name, value=val):
                #if min_val <= val <= max_val:
                    kwargs = {'ID': id_val, type_name: val}
                    status, row = self.db.insertRow("DATA_TYPES", **kwargs)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(getattr(row, type_name), val)
                #else:
                #    with self.assertRaises(OverflowError):
                #        kwargs = {'ID': id_val, type_name: val}
                #        self.db.insertRow("DATA_TYPES", **kwargs)
        if not_null:
            with self.assertRaises(ValueError):  # NOT NULL
                self.db.insertRow("DATA_TYPES", ID=5, **{type_name: None})
        status, row = self.db.insertRow("DATA_TYPES", ID=6)  # Test default
        self.assertEqual(getattr(row, type_name), default_val)
        trans.end()

    # Test all integer types
    def test_uint8(self):
        self._test_integer_type('U8', 0, 255, 10)

    def test_uint16(self):
        self._test_integer_type('U16', 0, 65535, 100, not_null=False)

    def test_uint32(self):
        self._test_integer_type('U32', 0, 4294967295, 1000)

    def test_uint64(self):
        self._test_integer_type('U64', 0, 18446744073709551615, 10000, not_null=False)

    def test_int8(self):
        self._test_integer_type('I8', -128, 127, 50)

    def test_int16(self):
        self._test_integer_type('I16', -32768, 32767, 500, not_null=False)

    def test_int32(self):
        self._test_integer_type('I32', -2147483648, 2147483647, 5000)

    def test_int64(self):
        self._test_integer_type('I64', -9223372036854775808, 9223372036854775807, 50000, not_null=False)

    # Test float types
    def test_float32(self):
        self._test_float_type('F32', np.finfo(np.float32).min, np.finfo(np.float32).max, np.float32(1.23))

    def test_float64(self):
        self._test_float_type('F64', np.finfo(np.float64).min, np.finfo(np.float64).max, 123.45, not_null=False)

    # Test decimal type DECY
    def test_decimal_normal(self):
        status, trans = self.db.startUpdate()
        # DECY is decimal(32,10), so up to 32 digits total, 10 after decimal
        values = [
            (1, Decimal('1234567890123456789012.3456789012')),
            (2, Decimal('-1234567890123456789012.3456789012')),
            (3, Decimal('0.0000000001')),
            (4, None)  # Test null
        ]
        for id_val, val in values:
            with self.subTest(value=val):
                status, row = self.db.insertRow("DATA_TYPES", ID=id_val, DECY=val)
                self.assertEqual(status, Status.Okay)
                self.assertEqual(row.DECY, val)
        # Test default (null)
        status, row = self.db.insertRow("DATA_TYPES", ID=5)
        self.assertIsNone(row.DECY)
        trans.end()

    # Test decimal type with an invalid BCD according to the schema
    def test_decimal_inv_bcd(self):
        status, trans = self.db.startUpdate()
        values = [(1, Decimal('99999999.99')), (2, Decimal('-99999999.99')), (3, Decimal('-99999999.99')), (4, Decimal('100000000.00'))]  # Assuming decimal(10,2)
        for id_val, val in values:
            with self.subTest(value=val):
                if Decimal('-99999999.99') <= val <= Decimal('99999999.99'):
                    status, row = self.db.insertRow("DATA_TYPES", ID=id_val, DECX=val)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(row.DECX, val)
                else:
                    with self.assertRaises(ErrorInvBcd):
                        self.db.insertRow("DATA_TYPES", ID=id_val, DECX=val)
        with self.assertRaises(ValueError):  # NOT NULL
            self.db.insertRow("DATA_TYPES", ID=4, DECX=None)
        status, row = self.db.insertRow("DATA_TYPES", ID=5)  # Test default
        self.assertEqual(row.DECX, Decimal('999.99'))
        trans.end()

    # Test inserting a Decimal with more than 32 digits (should raise ValueError)
    def test_decimal_too_large(self):
        status, trans = self.db.startUpdate()
        with self.assertRaises(ValueError):
            self.db.insertRow("DATA_TYPES", ID=100, DECY=Decimal('123456789012345678901234567890.1234567890'))
        trans.end()

    # Test char type (single character)
    def test_char(self):
        status, trans = self.db.startUpdate()
        values = [(1, 'B'), (2, ''), (3, 'AB'), (4, '€'), (5, '𐍈')]  # 1, 0, 2, 3, 4 bytes
        for id_val, val in values:
            with self.subTest(value=val):
                if len(val) <= 1:
                    status, row = self.db.insertRow("DATA_TYPES", ID=id_val, C=val)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(row.C, val or '')
                else:
                    with self.assertRaises(ErrorBadDataLen):  # Should fail for multi-char strings
                        self.db.insertRow("DATA_TYPES", ID=id_val, C=val)
        with self.assertRaises(ValueError):  # NOT NULL
            self.db.insertRow("DATA_TYPES", ID=6, C=None)
        status, row = self.db.insertRow("DATA_TYPES", ID=7)  # Test default
        self.assertEqual(row.C, 'A')
        trans.end()

    # Test char(10) type
    def test_char10(self):
        status, trans = self.db.startUpdate()
        values = [(1, 'short'), (2, 'exactlyten'), (3, 'toolongstring'), (4, '€€€€€'), (5, '𐍈𐍈')]  # Varying byte lengths
        for id_val, val in values:
            with self.subTest(value=val):
                if len(val) <= 10:
                    status, row = self.db.insertRow("DATA_TYPES", ID=id_val, C10=val)
                    self.assertEqual(status, Status.Okay)
                    expected = val if val else 'abcdefghij'
                    self.assertEqual(row.C10, expected)
                else:
                    with self.assertRaises(Exception):  # Truncate or error
                        self.db.insertRow("DATA_TYPES", ID=id_val, C10=val)
        status, row = self.db.insertRow("DATA_TYPES", ID=6)  # Test default
        self.assertEqual(row.C10, 'abcdefghij')
        trans.end()

    # Test varchar(10) type
    def test_varchar10(self):
        status, trans = self.db.startUpdate()
        values = [(1, 'short'), (2, 'exactlyten'), (3, 'toolongstring'), (4, '€€€€€'), (5, '𐍈𐍈')]  # Varying byte lengths
        for id_val, val in values:
            with self.subTest(value=val):
                if len(val) <= 10:
                    status, row = self.db.insertRow("DATA_TYPES", ID=id_val, VC=val)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(row.VC, val)
                else:
                    with self.assertRaises(ErrorBadDataLen):  # Should fail for strings longer than 10 chars
                        self.db.insertRow("DATA_TYPES", ID=id_val, VC=val)
        with self.assertRaises(ValueError):  # NOT NULL
            self.db.insertRow("DATA_TYPES", ID=6, VC=None)
        status, row = self.db.insertRow("DATA_TYPES", ID=7)  # Test default
        self.assertEqual(row.VC, 'test')
        trans.end()

    # Test uuid type
    def test_uuid(self):
        status, trans = self.db.startUpdate()
        test_uuid = uuid.UUID('12345678-1234-5678-1234-567812345678')
        nil_uuid = uuid.UUID(int=0)
        max_uuid = uuid.UUID('ffffffff-ffff-ffff-ffff-ffffffffffff')
        values = [
            (1, test_uuid),
            (2, nil_uuid),
            (3, max_uuid),
            (4, None),  # Test null
        ]
        for id_val, val in values:
            with self.subTest(value=val):
                status, row = self.db.insertRow("DATA_TYPES", ID=id_val, UID=val)
                self.assertEqual(status, Status.Okay)
                if val is None:
                    self.assertIsNone(row.UID)
                else:
                    self.assertEqual(row.UID, val)
                    self.assertIsInstance(row.UID, uuid.UUID)
        # Test default (null)
        status, row = self.db.insertRow("DATA_TYPES", ID=5)
        self.assertIsNone(row.UID)
        # Test round-trip with string input
        status, row = self.db.insertRow("DATA_TYPES", ID=6, UID='12345678-1234-5678-1234-567812345678')
        self.assertEqual(status, Status.Okay)
        self.assertEqual(row.UID, test_uuid)
        trans.end()

    # Test varchar(10 octets) type
    def test_varchar10_octets(self):
        status, trans = self.db.startUpdate()
        values = [
            (1, '1234567890'),  # 10 bytes
            (2, '€€€'),  # 3 chars, 9 bytes
            (3, '𐍈𐍈'),  # 2 chars, 8 bytes
            (4, '12345678901'),  # 11 bytes, should fail
            (5, '€€€€'),  # 4 chars, 12 bytes, should fail
        ]
        for id_val, val in values:
            with self.subTest(value=val):
                if len(val.encode('utf-8')) <= 10:
                    status, row = self.db.insertRow("DATA_TYPES", ID=id_val, VC_OCTET=val)
                    self.assertEqual(status, Status.Okay)
                    self.assertEqual(row.VC_OCTET, val)
                else:
                    with self.assertRaises(ValueError):  # Should fail if byte length > 10
                        self.db.insertRow("DATA_TYPES", ID=id_val, VC_OCTET=val)
        with self.assertRaises(ValueError):  # NOT NULL
            self.db.insertRow("DATA_TYPES", ID=6, VC_OCTET=None)
        status, row = self.db.insertRow("DATA_TYPES", ID=7)  # Test default
        self.assertEqual(row.VC_OCTET, 'octet')
        trans.end()

if __name__ == '__main__':
    unittest.main()