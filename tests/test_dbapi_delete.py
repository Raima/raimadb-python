#!/usr/bin/env python3
import unittest

from rdm.retcodetypes import Status

from _helpers import DbTestBase


SCHEMA = """
create table t1 (id int primary key);
create table t2 (id int primary key);
"""


class TestDeleteRows(DbTestBase):
    DB_NAME = "delete_test"
    SCHEMA = SCHEMA

    def _insert_rows(self, table, ids):
        _, trans = self.db.startUpdate()
        for i in ids:
            self.db.insertRow(table, ID=i)
        trans.end()

    def _count_rows(self, table):
        _, trans = self.db.startRead()
        _, cursor = self.db.getRows(table)
        count = 0
        while cursor.moveToNext() == Status.Okay:
            count += 1
        trans.end()
        return count

    def test_deleteAllRowsFromTable_empties_table(self):
        """deleteAllRowsFromTable removes all rows from the named table."""
        self._insert_rows("T1", [1, 2, 3])
        self.assertEqual(self._count_rows("T1"), 3)

        _, trans = self.db.startUpdate()
        status = self.db.deleteAllRowsFromTable("T1")
        self.assertEqual(status, Status.Okay)
        trans.end()

        self.assertEqual(self._count_rows("T1"), 0)

    def test_deleteAllRowsFromTable_only_affects_named_table(self):
        """deleteAllRowsFromTable leaves other tables untouched."""
        self._insert_rows("T1", [1, 2])
        self._insert_rows("T2", [10, 20, 30])

        _, trans = self.db.startUpdate()
        self.db.deleteAllRowsFromTable("T1")
        trans.end()

        self.assertEqual(self._count_rows("T1"), 0)
        self.assertEqual(self._count_rows("T2"), 3)

    def test_deleteAllRowsFromTable_invalid_table(self):
        """deleteAllRowsFromTable with unknown table raises an exception."""
        _, trans = self.db.startUpdate()
        with self.assertRaises(Exception):
            self.db.deleteAllRowsFromTable("NONEXISTENT_TABLE")
        trans.end()

    def test_deleteAllRowsFromDatabase_empties_all_tables(self):
        """deleteAllRowsFromDatabase removes rows from every table."""
        self._insert_rows("T1", [1, 2])
        self._insert_rows("T2", [10, 20, 30])

        _, trans = self.db.startUpdate()
        status = self.db.deleteAllRowsFromDatabase()
        self.assertEqual(status, Status.Okay)
        trans.end()

        self.assertEqual(self._count_rows("T1"), 0)
        self.assertEqual(self._count_rows("T2"), 0)


class TestTableSetMaxRows(DbTestBase):
    DB_NAME = "maxrows_test"
    SCHEMA = "create table t (id int primary key);"

    def test_tableSetMaxRows_enforced(self):
        """After tableSetMaxRows(2), inserting a 3rd row raises an error."""
        status = self.db.tableSetMaxRows("T", 2)
        self.assertEqual(status, Status.Okay)

        _, trans = self.db.startUpdate()
        self.db.insertRow("T", ID=1)
        self.db.insertRow("T", ID=2)
        with self.assertRaises(Exception):
            self.db.insertRow("T", ID=3)
        trans.end()

    def test_tableSetMaxRows_invalid_table(self):
        """tableSetMaxRows with unknown table raises an exception."""
        with self.assertRaises(Exception):
            self.db.tableSetMaxRows("NONEXISTENT_TABLE", 10)


if __name__ == '__main__':
    unittest.main()
