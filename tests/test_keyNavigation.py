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

class KeyNavigationTest(unittest.TestCase):
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
                id int primary key,
                val1 int unique,
                val2 int unique
            );
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog for database")
        status = self.db.open("cyton-test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
        self.tfs.dropDatabase("cyton-test")
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay, "Failed to free TFS")

    def insert_test_data(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay, "Failed to start update")
        # Insert 5 rows with ID, VAL1, VAL2
        rows = [
            (1, 100, 200),
            (2, 50, 150),
            (3, 75, 175),
            (4, 25, 125),
            (5, 10, 100)
        ]
        for id_val, val1, val2 in rows:
            status, _ = self.db.insertRow("SIMPLE", ID=id_val, VAL1=val1, VAL2=val2)
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
        expected = [(1, 100, 200), (2, 50, 150), (3, 75, 175), (4, 25, 125), (5, 10, 100)]
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

    def test_get_rows_by_val1_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")
        
        # Expected rows in VAL1 order (ascending)
        expected = [(5, 10, 100), (4, 25, 125), (2, 50, 150), (3, 75, 175), (1, 100, 200)]
        retrieved = []
        while True:
            status = cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")
            retrieved.append((cursor.ID, cursor.VAL1, cursor.VAL2))
        
        self.assertEqual(retrieved, expected, "Rows not retrieved in VAL1 key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_get_rows_by_val2_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "VAL2")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL2 key")
        
        # Expected rows in VAL2 order (ascending)
        expected = [(5, 10, 100), (4, 25, 125), (2, 50, 150), (3, 75, 175), (1, 100, 200)]
        retrieved = []
        while True:
            status = cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")
            retrieved.append((cursor.ID, cursor.VAL1, cursor.VAL2))
        
        self.assertEqual(retrieved, expected, "Rows not retrieved in VAL2 key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_row_scan_cursor_move_to_key_primary(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRows("SIMPLE")
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
            status = cursor.moveToKey("ID", ID=key_value)
            self.assertEqual(status, Status.Okay, f"Failed to move to key ID={key_value}")
            retrieved_row = (cursor.ID, cursor.VAL1, cursor.VAL2)
            self.assertEqual(retrieved_row, expected_row, f"Row not correct after moving to ID={key_value}")
        
        # Optionally test a non-existent key
        # Since this is a key scan cursor we get an exception as oposed to the next test
        with self.assertRaises(ErrorNotInCursor):
            status = cursor.moveToKey("ID", ID=6)
        #self.assertNotIsInstance(status, StatusOkay, "Unexpectedly succeeded moving to non-existent key ID=6")
        
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_primary_key_cursor_move_to_key_primary(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "ID")
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
            status = cursor.moveToKey("ID", ID=key_value)
            self.assertEqual(status, Status.Okay, f"Failed to move to key ID={key_value}")
            retrieved_row = (cursor.ID, cursor.VAL1, cursor.VAL2)
            self.assertEqual(retrieved_row, expected_row, f"Row not correct after moving to ID={key_value}")
        
        # Optionally test a non-existent key
        status = cursor.moveToKey("ID", ID=6)
        self.assertEqual(status, Status.NotFound, "Unexpectedly succeeded moving to non-existent key ID=6")

        # The previous operation moved to key position 6 which is between 5 and after_last
        # so we can move to the previous key position which should be 5
        status = cursor.moveToPrevious()
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2)
        self.assertEqual(retrieved, (5, 10, 100), "Rows not retrieved in VAL1 key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_move_to_after_last_and_before_first(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, cursor = self.db.getRowsByKey("SIMPLE", "ID")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        
        status = cursor.moveToAfterLast()
        self.assertEqual(status, Status.Okay, "Failed moving to after last")

        # We can move to the previous key position which should be 5
        status = cursor.moveToPrevious()
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2)
        self.assertEqual(retrieved, (5, 10, 100), "Rows not retrieved in VAL1 key order")

        status = cursor.moveToBeforeFirst()
        self.assertEqual(status, Status.Okay, "Failed moving to before first")

        # We can move to the next key position which should be 1
        status = cursor.moveToNext()
        retrieved = (cursor.ID, cursor.VAL1, cursor.VAL2)
        self.assertEqual(retrieved, (1, 100, 200), "Rows not retrieved in VAL1 key order")

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

if __name__ == '__main__':
    unittest.main()