#!/usr/bin/env python3
"""Tests for cursor derivation methods: getClone, getSelf, getRowsAtPosition,
getRowsByKeyAtPosition, getRowsInReverseOrder."""
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


class CursorDerivationTest(unittest.TestCase):
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

    def insert_test_data(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        for v in [50, 10, 30, 40, 20]:
            status, _ = self.db.insertRow("SIMPLE", VAL1=v)
            self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getClone_independent_movement(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        original_val = cursor.VAL1

        status, clone = cursor.getClone()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(clone.VAL1, original_val)

        # Move clone forward; original should stay
        status = clone.moveToNext()
        self.assertEqual(status, Status.Okay)
        self.assertNotEqual(clone.VAL1, original_val)
        self.assertEqual(cursor.VAL1, original_val)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getSelf_singleton(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToKey("VAL1", VAL1=30)
        self.assertEqual(status, Status.Okay)

        status, single = cursor.getSelf()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(single.VAL1, 30)
        self.assertEqual(single.getCount(), 1)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getRowsAtPosition(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToKey("VAL1", VAL1=30)
        self.assertEqual(status, Status.Okay)

        status, derived = cursor.getRowsAtPosition()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(derived.VAL1, 30)
        self.assertEqual(derived.getCount(), cursor.getCount())

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getRowsByKeyAtPosition(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        starting_val = cursor.VAL1

        status, derived = cursor.getRowsByKeyAtPosition("VAL1")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(derived.VAL1, starting_val)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getRowsByKeyAtPosition_invalid_key_raises(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)

        with self.assertRaises(Exception):
            cursor.getRowsByKeyAtPosition("NON_EXISTENT_KEY")

        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getRowsInReverseOrder(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)

        status, forward = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay)

        forward_vals = []
        status = forward.moveToFirst()
        while status == Status.Okay:
            forward_vals.append(forward.VAL1)
            status = forward.moveToNext()

        status, reverse = forward.getRowsInReverseOrder()
        self.assertEqual(status, Status.Okay)

        reverse_vals = []
        status = reverse.moveToFirst()
        while status == Status.Okay:
            reverse_vals.append(reverse.VAL1)
            status = reverse.moveToNext()

        self.assertEqual(reverse_vals, list(reversed(forward_vals)))

        status = trans.end()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
