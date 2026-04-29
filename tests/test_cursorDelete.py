#!/usr/bin/env python3
"""Tests for cursor delete methods: deleteRow, unlinkAndDeleteRow."""
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


class CursorDeleteTest(unittest.TestCase):
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
            create table SIMPLE (
                ID int primary key not null,
                VAL1 int unique
            );
            create table OWNER (
                ID int primary key not null,
                NAME char(20)
            );
            create table "MEMBER" (
                ID int primary key not null,
                OWNER_ID int,
                NAME char(20),
                foreign key (OWNER_ID) references OWNER(ID)
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

    def insert_simple_data(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        for i, v in enumerate([10, 20, 30, 40, 50], start=1):
            status, _ = self.db.insertRow("SIMPLE", ID=i, VAL1=v)
            self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_deleteRow_decreases_count(self):
        self.insert_simple_data()
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        before_count = cursor.getCount()
        self.assertEqual(before_count, 5)

        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        status = cursor.deleteRow()
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        # Re-query to verify
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor2 = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor2.getCount(), 4)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_deleteRow_clears_at_row(self):
        self.insert_simple_data()
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertTrue(cursor._isAtRow())
        status = cursor.deleteRow()
        self.assertEqual(status, Status.Okay)
        self.assertFalse(cursor._isAtRow())
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_unlinkAndDeleteRow_owner(self):
        # Insert one owner with one linked member
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("OWNER", ID=1, NAME="alpha")
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("MEMBER", ID=10, OWNER_ID=1, NAME="m1")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        # Delete the member with unlinkAndDeleteRow
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        status = cursor.unlinkAndDeleteRow()
        self.assertEqual(status, Status.Okay)
        self.assertFalse(cursor._isAtRow())
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        # Verify member gone
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor2 = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor2.getCount(), 0)
        status = trans.end()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
