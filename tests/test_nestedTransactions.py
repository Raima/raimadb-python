#!/usr/bin/env python3
import sys

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

class TestTransactions(unittest.TestCase):
    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay, "Failed to initialize TFS")
        try:
            self.tfs.dropDatabase("trans_test")
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog("""
            create table test_table (id int primary key, val int);
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog")
        status = self.db.open("trans_test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
        self.tfs.dropDatabase("trans_test")
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay, "Failed to free TFS")

    def test_nested_commit(self):
        status, t1 = self.db.startUpdate()
        status, row1 = self.db.insertRow("TEST_TABLE", ID=1, VAL=100)
        self.assertEqual(status, Status.Okay)
        status, t2 = self.db.startUpdate()
        status, row2 = self.db.insertRow("TEST_TABLE", ID=2, VAL=200)
        self.assertEqual(status, Status.Okay)
        status = t2.end()  # Merges changes into t1
        status = t1.end()  # Commits all
        self.assertEqual(status, Status.Okay)
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        status = cursor.moveToNext()
        self.assertEqual(cursor.VAL, 100)
        status = cursor.moveToNext()
        self.assertEqual(cursor.VAL, 200)
        trans.end()

    def test_nested_rollback_inner(self):
        status, t1 = self.db.startUpdate()
        status, row1 = self.db.insertRow("TEST_TABLE", ID=1, VAL=100)
        self.assertEqual(status, Status.Okay)
        status, t2 = self.db.startUpdate()
        status, row2 = self.db.insertRow("TEST_TABLE", ID=2, VAL=200)
        self.assertEqual(status, Status.Okay)
        status = t2.rollback()  # Discards id=2
        status = t1.end()  # Commits id=1
        self.assertEqual(status, Status.Okay)
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        status = cursor.moveToNext()
        self.assertEqual(cursor.VAL, 100)
        status = cursor.moveToNext()
        self.assertEqual(status, Status.EndOfCursor)
        trans.end()

    def test_nested_rollback_outer(self):
        status, t1 = self.db.startUpdate()
        status, row1 = self.db.insertRow("TEST_TABLE", ID=1, VAL=100)
        self.assertEqual(status, Status.Okay)
        status, t2 = self.db.startUpdate()
        status, row2 = self.db.insertRow("TEST_TABLE", ID=2, VAL=200)
        self.assertEqual(status, Status.Okay)
        status = t2.end()  # Merges into t1
        status = t1.rollback()  # Rolls back all
        self.assertEqual(status, Status.Okay)
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        status = cursor.moveToNext()
        self.assertEqual(status, Status.EndOfCursor)
        trans.end()

if __name__ == '__main__':
    unittest.main()