#!/usr/bin/env python3
"""Tests for cursor inspection methods: getStatus, getType, getTableId, getRowId,
getCount, getLockStatus, isAfterLast, isBeforeFirst, getDatabase."""
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


class CursorInspectionTest(unittest.TestCase):
    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay)
        try:
            self.tfs.dropDatabase("cyton-test")
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog("""
            create table simple (
                id rowid primary key,
                val1 int unique
            );
        """)
        self.assertEqual(status, Status.Okay)
        status = self.db.open("cyton-test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay)

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted))
        try:
            self.tfs.dropDatabase("cyton-test")
        except ErrorNoDB:
            pass
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay)

    def insert_test_data(self, n=5):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        for v in range(1, n + 1):
            status, _ = self.db.insertRow("SIMPLE", VAL1=v * 10)
            self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getStatus(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)

        status = cursor.moveToBeforeFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getStatus(), CursorStatus.BEFORE_FIRST)

        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getStatus(), CursorStatus.AT_ROW)

        status = cursor.moveToAfterLast()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getStatus(), CursorStatus.AFTER_LAST)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getType(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor1 = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        t1 = cursor1.getType()
        self.assertIsInstance(t1, CursorType)

        status, cursor2 = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        t2 = cursor2.getType()
        self.assertIsInstance(t2, CursorType)
        # Different access methods should yield different cursor types
        self.assertNotEqual(t1, t2)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getTableId(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        table_id = cursor.getTableId()
        self.assertIsInstance(table_id, int)
        self.assertGreater(table_id, 0)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getRowId_distinct_per_row(self):
        self.insert_test_data(5)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        rowids = []
        status = cursor.moveToFirst()
        while status == Status.Okay:
            rowids.append(cursor.getRowId())
            status = cursor.moveToNext()
        self.assertEqual(len(rowids), 5)
        self.assertEqual(len(set(rowids)), 5)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getCount(self):
        self.insert_test_data(5)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getCount(), 5)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getLockStatus_read(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getLockStatus(), LockStatus.READ)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getLockStatus_write(self):
        self.insert_test_data()
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.getLockStatus(), LockStatus.WRITE)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_isAfterLast_isBeforeFirst(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)

        status = cursor.moveToBeforeFirst()
        self.assertEqual(status, Status.Okay)
        self.assertTrue(cursor.isBeforeFirst())
        self.assertFalse(cursor.isAfterLast())

        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertFalse(cursor.isBeforeFirst())
        self.assertFalse(cursor.isAfterLast())

        status = cursor.moveToAfterLast()
        self.assertEqual(status, Status.Okay)
        self.assertFalse(cursor.isBeforeFirst())
        self.assertTrue(cursor.isAfterLast())

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getDatabase_returns_db(self):
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        self.assertIs(cursor.getDatabase(), self.db)
        status = trans.end()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
