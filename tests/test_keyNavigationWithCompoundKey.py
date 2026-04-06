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

class KeyNavigationWithCompoundKeyTest(unittest.TestCase):
    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay, "Failed to initialize TFS")
        try:
            self.tfs.dropDatabase("cyton-test")
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog("""
            create table simple (
                id int,
                val1 int,
                val2 int,
                str char(20),
                constraint compound_key primary key (id, val1, val2, str)
            );
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog for database")
        status = self.db.open("cyton-test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
        #status = self.tfs.dropDatabase("cyton-test")
        #self.assertEqual(status, Status.Okay, "Failed to drop database 'cyton-test'")
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay, "Failed to free TFS")

    def insert_test_data(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay, "Failed to start update")
        # Insert 5 rows with ID, VAL1, VAL2
        rows = [
            (1, 100, 200, "row1"),
            (1, 100, 201, "row2"),
            (1, 101, 200, "row3"),
            (2, 50, 150, "row4"),
            (3, 75, 175, "row5"),
            (4, 25, 125, "row6"),
            (5, 10, 100, "row7")
        ]
        for id_val, val1, val2, str in rows:
            status, _ = self.db.insertRow("SIMPLE", ID=id_val, VAL1=val1, VAL2=val2, STR=str)
            self.assertEqual(status, Status.Okay, f"Failed to insert row with ID={id_val}")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_get_rows_by_primary_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRows("SIMPLE")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        
        # Expected rows in primary key (ID) order
        expected = [(1, 100, 200), (1, 100, 201), (1, 101, 200),(2, 50, 150), (3, 75, 175), (4, 25, 125), (5, 10, 100)]
        retrieved = []
        while True:
            status = cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")
            retrieved.append((cursor.ID, cursor.VAL1, cursor.VAL2))
        
        self.assertEqual(retrieved, expected, "Rows not retrieved in primary key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_compound_primary_key_cursor_move_to_sub_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "COMPOUND_KEY")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        
        # Test moving to specific primary key values in non-sequential order
        test_cases = [
            (3, (3, 75, 175)),
            (1, (1, 100, 200)),
            (5, (5, 10, 100)),
            (2, (2, 50, 150)),
            (4, (4, 25, 125))
        ]
        for key_value, expected_row in test_cases:
            status = cursor.moveToKey("COMPOUND_KEY", ID=key_value)
            self.assertEqual(status, Status.Okay, f"Failed to move to key ID={key_value}")
            retrieved_row = (cursor.ID, cursor.VAL1, cursor.VAL2)
            self.assertEqual(retrieved_row, expected_row, f"Row not correct after moving to ID={key_value}")
        
        status = cursor.moveToKey("COMPOUND_KEY", ID=1, VAL1= 101)
        self.assertEqual(status, Status.Okay, "Could not find key ID=1, VAL1=101")
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2)
        self.assertEqual(retrieved, (1, 101, 200), "Rows not retrieved in VAL1 key order")

        status = cursor.moveToPrevious()
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2)
        self.assertEqual(retrieved, (1, 100, 201), "Rows not retrieved in VAL1 key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_compound_primary_key_cursor_move_to_invalid_specified_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "COMPOUND_KEY")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        
        with self.assertRaises(ValueError):
            cursor.moveToKey("COMPOUND_KEY", ID=1, VAL2=200)

        with self.assertRaises(ValueError):
            cursor.moveToKey("COMPOUND_KEY", VAL1=100, VAL2=200)

        with self.assertRaises(ValueError):
            cursor.moveToKey("COMPOUND_KEY", ID=1, VAL2=200)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_compound_primary_key_cursor_move_to_key_with_substing(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "COMPOUND_KEY")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        
        status = cursor.moveToKey("COMPOUND_KEY", ID=1, VAL1=100, VAL2=200, STR="row1")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2, cursor.STR)
        self.assertEqual(retrieved, (1, 100, 200, "row1"), "Rows not retrieved in VAL1 key order")

        with self.assertRaises(ValueError):
            status = cursor.moveToKey("COMPOUND_KEY", 2, ID=1, VAL1=100, VAL2=200)

        status = cursor.moveToKey("COMPOUND_KEY", 2, ID=1, VAL1=100, VAL2=200, STR="ro")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2, cursor.STR)
        self.assertEqual(retrieved, (1, 100, 200, "row1"), "Rows not retrieved in VAL1 key order")

        status = cursor.moveToKey("COMPOUND_KEY", ID=1, VAL1=100, VAL2=200, STR="ro")
        self.assertEqual(status, Status.NotFound, "We should fail to get rows")

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

if __name__ == '__main__':
    unittest.main()