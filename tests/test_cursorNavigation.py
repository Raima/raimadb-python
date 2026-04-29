#!/usr/bin/env python3
"""Tests for new cursor navigation methods: moveToPosition, moveToRowId."""
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


class CursorNavigationTest(unittest.TestCase):
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
                val1 int unique,
                val2 int unique
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

    def insert_test_data(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        for val1, val2 in [(100, 200), (50, 150), (75, 175), (25, 125), (10, 100)]:
            status, _ = self.db.insertRow("SIMPLE", VAL1=val1, VAL2=val2)
            self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_moveToPosition(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, source = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        status, target = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)

        # Move source to a known row (VAL1=50)
        status = source.moveToKey("VAL1", VAL1=50)
        self.assertEqual(status, Status.Okay)
        self.assertEqual(source.VAL1, 50)

        # Move target to source's position
        status = target.moveToPosition(source)
        self.assertEqual(status, Status.Okay)
        self.assertEqual(target.VAL1, 50)
        self.assertEqual(target.VAL2, 150)
        self.assertTrue(target._isAtRow())

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_moveToRowId(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToKey("VAL1", VAL1=50)
        self.assertEqual(status, Status.Okay)
        first_val2 = cursor.VAL2
        rowid = cursor.getRowId()
        self.assertIsInstance(rowid, int)

        # Move away
        status = cursor.moveToLast()
        self.assertEqual(status, Status.Okay)
        self.assertNotEqual(cursor.VAL1, 50)

        # Return via rowid
        status = cursor.moveToRowId(rowid)
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.VAL1, 50)
        self.assertEqual(cursor.VAL2, first_val2)
        self.assertTrue(cursor._isAtRow())

        status = trans.end()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
