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

class CursorComparisonTest(unittest.TestCase):
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

    def test_cursor_comparisons_on_row_val1_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, fixed_cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")
        status = fixed_cursor.moveToKey("VAL1", VAL1=50)
        self.assertEqual(status, Status.Okay, "Failed to move to key VAL1=50")

        status, iter_cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")

        # Expected positions in VAL1 order: 10(ID5), 25(ID4), 50(ID2), 75(ID3), 100(ID1)
        # Fixed at 50 (position 3)
        positions = [10, 25, 50, 75, 100]
        fixed_val = 50

        retrieved = []
        status = iter_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first")
        while True:
            current_val = iter_cursor.VAL1
            retrieved.append(current_val)

            # Perform all six comparisons
            self.assertEqual(iter_cursor < fixed_cursor, current_val < fixed_val, f"< comparison failed at {current_val}")
            self.assertEqual(iter_cursor <= fixed_cursor, current_val <= fixed_val, f"<= comparison failed at {current_val}")
            self.assertEqual(iter_cursor > fixed_cursor, current_val > fixed_val, f"> comparison failed at {current_val}")
            self.assertEqual(iter_cursor >= fixed_cursor, current_val >= fixed_val, f">= comparison failed at {current_val}")
            self.assertEqual(iter_cursor == fixed_cursor, current_val == fixed_val, f"== comparison failed at {current_val}")
            self.assertEqual(iter_cursor != fixed_cursor, current_val != fixed_val, f"!= comparison failed at {current_val}")

            status = iter_cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")

        self.assertEqual(retrieved, positions, "Rows not retrieved in VAL1 key order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_cursor_comparisons_between_rows_val1_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, fixed_cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")
        status = fixed_cursor.moveToKey("VAL1", VAL1=60)  # Between 50 and 75
        self.assertEqual(status, Status.NotFound, "Unexpected status when moving to non-existent key VAL1=60")

        status, iter_cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")

        # Expected positions in VAL1 order: 10, 25, 50, 75, 100
        # Fixed positioned as if at 60
        positions = [10, 25, 50, 75, 100]
        fixed_val = 60

        retrieved = []
        status = iter_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first")
        while True:
            current_val = iter_cursor.VAL1
            retrieved.append(current_val)

            # Perform all six comparisons (== and != should be false since not on a row exactly)
            self.assertEqual(iter_cursor < fixed_cursor, current_val < fixed_val, f"< comparison failed at {current_val}")
            self.assertEqual(iter_cursor <= fixed_cursor, current_val <= fixed_val, f"<= comparison failed at {current_val}")
            self.assertEqual(iter_cursor > fixed_cursor, current_val > fixed_val, f"> comparison failed at {current_val}")
            self.assertEqual(iter_cursor >= fixed_cursor, current_val >= fixed_val, f">= comparison failed at {current_val}")
            self.assertFalse(iter_cursor == fixed_cursor, f"== comparison failed at {current_val}")
            self.assertTrue(iter_cursor != fixed_cursor, f"!= comparison failed at {current_val}")

            status = iter_cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")

        self.assertEqual(retrieved, positions, "Rows not retrieved in VAL1 key order")

        # Additional verification: moveToPrevious from fixed should go to 50
        status = fixed_cursor.moveToPrevious()
        self.assertEqual(status, Status.Okay, "Failed to move to previous from between position")
        self.assertEqual(fixed_cursor.VAL1, 50, "Incorrect position after moveToPrevious")

        # moveToNext from there should go to 75
        status = fixed_cursor.moveToNext()
        self.assertEqual(status, Status.Okay, "Failed to move to next from previous position")
        self.assertEqual(fixed_cursor.VAL1, 75, "Incorrect position after moveToNext")

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_cursor_comparisons_between_rows_id_key(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, fixed_cursor = self.db.getRowsByKey("SIMPLE", "VAL1")
        self.assertEqual(status, Status.Okay, "Failed to get rows by VAL1 key")
        status = fixed_cursor.moveToKey("VAL1", VAL1=60)  # Between 50 and 75
        self.assertEqual(status, Status.NotFound, "Unexpected status when moving to non-existent key VAL1=60")

        status, iter_cursor = self.db.getRowsByKey("SIMPLE", "ID")
        self.assertEqual(status, Status.Okay, "Failed to get rows by ID key")

        # Expected VAL1 in ID order: ID1:100, ID2:50, ID3:75, ID4:25, ID5:10
        positions = [100, 50, 75, 25, 10]

        retrieved = []
        status = iter_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first")
        while True:
            current_val = iter_cursor.VAL1
            retrieved.append(current_val)

            # Expect exceptions for all six comparisons
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor < fixed_cursor
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor <= fixed_cursor
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor > fixed_cursor
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor >= fixed_cursor
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor == fixed_cursor
            with self.assertRaises(ErrorNotInCursor):
                _ = iter_cursor != fixed_cursor

            status = iter_cursor.moveToNext()
            if status == Status.EndOfCursor:
                break
            self.assertEqual(status, Status.Okay, "Failed to move to next row")

        self.assertEqual(retrieved, positions, "Rows not retrieved in ID key order")

        # Additional verification: moveToPrevious from fixed should go to 50
        status = fixed_cursor.moveToPrevious()
        self.assertEqual(status, Status.Okay, "Failed to move to previous from between position")
        self.assertEqual(fixed_cursor.VAL1, 50, "Incorrect position after moveToPrevious")

        # moveToNext from there should go to 75
        status = fixed_cursor.moveToNext()
        self.assertEqual(status, Status.Okay, "Failed to move to next from previous position")
        self.assertEqual(fixed_cursor.VAL1, 75, "Incorrect position after moveToNext")

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")
if __name__ == "__main__":
    unittest.main()