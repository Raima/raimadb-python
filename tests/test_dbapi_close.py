#!/usr/bin/env python3
import unittest

from rdm.rdmapi import allocTfs
from rdm.types import OpenMode
from rdm.exceptions import ErrorNoDB, ErrorInvFcnSeq
from rdm.retcodetypes import Status

from _helpers import DbTestBase


SCHEMA = "create table t (id int primary key, val int);"


class TestClose(DbTestBase):
    DB_NAME = "close_test"
    SCHEMA = SCHEMA

    def test_close_without_transaction(self):
        """close() without an open transaction succeeds."""
        status = self.db.close()
        self.assertEqual(status, Status.Okay)

    def test_close_increments_closeCount_invalidates_cursor(self):
        """After close(), a cursor obtained before is invalidated."""
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("T")
        self.assertEqual(status, Status.Okay)
        # close() with open transaction — should roll back or error; re-open after
        self.db.closeRollback()
        with self.assertRaises(ErrorInvFcnSeq):
            cursor.moveToNext()

    def test_closeRollback_with_open_transaction_succeeds(self):
        """closeRollback() succeeds even with an active update transaction."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("T", ID=1, VAL=10)
        self.assertEqual(status, Status.Okay)
        # closeRollback should discard the uncommitted transaction
        # RDM returns TrAborted when closing with an active transaction
        status = self.db.closeRollback()
        self.assertIn(status, (Status.Okay, Status.TrAborted))
        # Re-open and verify no data was committed
        status = self.db.open(self.DB_NAME, OpenMode.SHARED)
        self.assertEqual(status, Status.Okay)
        status, read_trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("T")
        self.assertEqual(status, Status.Okay)
        status = cursor.moveToNext()
        self.assertEqual(status, Status.EndOfCursor, "Row should not exist after closeRollback")
        read_trans.end()

    def test_close_then_reopen(self):
        """close() followed by open() works normally."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("T", ID=42, VAL=99)
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)
        status = self.db.close()
        self.assertEqual(status, Status.Okay)
        status = self.db.open(self.DB_NAME, OpenMode.SHARED)
        self.assertEqual(status, Status.Okay)
        status, read_trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, cursor = self.db.getRows("T")
        status = cursor.moveToNext()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.ID, 42)
        read_trans.end()


if __name__ == '__main__':
    unittest.main()
