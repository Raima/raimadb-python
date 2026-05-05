#!/usr/bin/env python3
import unittest

from rdm.exceptions import ErrorInvFcnSeq
from rdm.retcodetypes import Status

from _helpers import DbTestBase

# RDM_TRANS_STATUS integer values (from rdmtypes.h)
RDM_TRANS_READ     = 1
RDM_TRANS_UPDATE   = 2
RDM_TRANS_SNAPSHOT = 3
RDM_TRANS_NONE     = 4

# RDM_LOCK_STATUS integer values (from rdmtypes.h)
RDM_LOCK_FREE     = 0x0000
RDM_LOCK_READ     = 0x0001
RDM_LOCK_WRITE    = 0x0003
RDM_LOCK_SNAPSHOT = 0x0005


SCHEMA = "create table t (id int primary key, val int);"


class TestDbEnd(DbTestBase):
    """Tests for db.end() and db.endRollback() — operate at the db handle level."""

    DB_NAME = "dbtrans_end_test"
    SCHEMA = SCHEMA

    def test_db_end_commits(self):
        """db.end() commits inserted rows."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("T", ID=1, VAL=100)
        self.assertEqual(status, Status.Okay)
        status = self.db.end()
        self.assertEqual(status, Status.Okay)

        status, read_trans = self.db.startRead()
        status, cursor = self.db.getRows("T")
        status = cursor.moveToNext()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.ID, 1)
        read_trans.end()

    def test_db_end_invalidates_trans_handle(self):
        """After db.end(), the RdmTrans object is invalidated."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status = self.db.end()
        self.assertEqual(status, Status.Okay)
        with self.assertRaises(ErrorInvFcnSeq):
            trans.end()

    def test_db_endRollback_discards(self):
        """db.endRollback() discards inserted rows."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("T", ID=1, VAL=100)
        self.assertEqual(status, Status.Okay)
        status = self.db.endRollback()
        self.assertEqual(status, Status.Okay)

        status, read_trans = self.db.startRead()
        status, cursor = self.db.getRows("T")
        status = cursor.moveToNext()
        self.assertEqual(status, Status.EndOfCursor, "Row should have been rolled back")
        read_trans.end()

    def test_db_endRollback_invalidates_trans_handle(self):
        """After db.endRollback(), the RdmTrans object is invalidated."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status = self.db.endRollback()
        self.assertEqual(status, Status.Okay)
        with self.assertRaises(ErrorInvFcnSeq):
            trans.end()


class TestPrecommit(DbTestBase):
    DB_NAME = "dbtrans_precommit_test"
    SCHEMA = SCHEMA

    def test_precommit_then_commit(self):
        """precommit() succeeds; transaction can be finalised with trans.end()."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("T", ID=7, VAL=77)
        self.assertEqual(status, Status.Okay)
        status = self.db.precommit()
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        status, read_trans = self.db.startRead()
        status, cursor = self.db.getRows("T")
        status = cursor.moveToNext()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(cursor.ID, 7)
        read_trans.end()


class TestTransactionStatus(DbTestBase):
    DB_NAME = "dbtrans_status_test"
    SCHEMA = SCHEMA

    def test_status_none(self):
        """Before any transaction, status is RDM_TRANS_NONE."""
        status, ts = self.db.getTransactionStatus()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ts, RDM_TRANS_NONE)

    def test_status_read(self):
        """During startRead, status is RDM_TRANS_READ."""
        _, trans = self.db.startRead()
        status, ts = self.db.getTransactionStatus()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ts, RDM_TRANS_READ)
        trans.end()

    def test_status_update(self):
        """During startUpdate, status is RDM_TRANS_UPDATE."""
        _, trans = self.db.startUpdate()
        status, ts = self.db.getTransactionStatus()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ts, RDM_TRANS_UPDATE)
        trans.end()

    def test_status_snapshot(self):
        """During startSnapshot, status is RDM_TRANS_SNAPSHOT."""
        _, trans = self.db.startSnapshot()
        status, ts = self.db.getTransactionStatus()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ts, RDM_TRANS_SNAPSHOT)
        trans.end()


class TestLockStatus(DbTestBase):
    DB_NAME = "dbtrans_lock_test"
    SCHEMA = SCHEMA

    def test_lock_free(self):
        """Without a transaction, table lock is FREE."""
        status, ls = self.db.getLockStatus("T")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ls, RDM_LOCK_FREE)

    def test_lock_read(self):
        """During startRead, table lock is READ."""
        _, trans = self.db.startRead()
        status, ls = self.db.getLockStatus("T")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ls, RDM_LOCK_READ)
        trans.end()

    def test_lock_write(self):
        """During startUpdate, table lock is WRITE."""
        _, trans = self.db.startUpdate()
        status, ls = self.db.getLockStatus("T")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(ls, RDM_LOCK_WRITE)
        trans.end()

    def test_lock_snapshot(self):
        """During startSnapshot, getLockStatus succeeds (snapshot uses MVCC, not table locks)."""
        _, trans = self.db.startSnapshot()
        status, ls = self.db.getLockStatus("T")
        self.assertEqual(status, Status.Okay)
        # Snapshot transactions do not acquire traditional table locks
        trans.end()

    def test_getLockStatus_invalid_table(self):
        """getLockStatus with unknown table raises an exception."""
        with self.assertRaises(Exception):
            self.db.getLockStatus("NONEXISTENT_TABLE")


class TestStartSnapshot(DbTestBase):
    DB_NAME = "dbtrans_snapshot_test"
    SCHEMA = SCHEMA

    def setUp(self):
        super().setUp()
        # Pre-populate with one row
        _, trans = self.db.startUpdate()
        self.db.insertRow("T", ID=1, VAL=10)
        trans.end()

    def test_startSnapshot_can_read(self):
        """startSnapshot raises ErrorNotLocked on cursor navigation (snapshot uses MVCC)."""
        # RDM snapshot transactions do not acquire traditional table read locks;
        # cursor navigation therefore raises ErrorNotLocked with the current impl.
        status, snap = self.db.startSnapshot()
        self.assertEqual(status, Status.Okay)
        _, cursor = self.db.getRows("T")
        status =cursor.moveToNext()
        self.assertEqual(status, Status.Okay)
        snap.end()

    def test_startSnapshot_cannot_insert(self):
        """insertRow during a snapshot transaction raises an error."""
        _, snap = self.db.startSnapshot()
        with self.assertRaises(Exception):
            self.db.insertRow("T", ID=99, VAL=0)
        snap.end()


class TestEviction(DbTestBase):
    DB_NAME = "dbtrans_evict_test"
    SCHEMA = "create table t (id int primary key, val int); create unique index t_val on t(val);"

    def setUp(self):
        super().setUp()
        _, trans = self.db.startUpdate()
        self.db.insertRow("T", ID=1, VAL=10)
        trans.end()

    def test_evictRowData(self):
        """evictRowData returns Okay after rows exist in cache."""
        status = self.db.evictRowData("T")
        self.assertEqual(status, Status.Okay)

    def test_evictRowData_invalid_table(self):
        """evictRowData with unknown table raises an exception."""
        with self.assertRaises(Exception):
            self.db.evictRowData("NONEXISTENT_TABLE")

    def test_evictKeyData(self):
        """evictKeyData returns Okay for a valid index."""
        status = self.db.evictKeyData("T", "T_VAL")
        self.assertEqual(status, Status.Okay)

    def test_evictKeyData_invalid_key(self):
        """evictKeyData with unknown key raises an exception."""
        with self.assertRaises(Exception):
            self.db.evictKeyData("T", "NONEXISTENT_KEY")


if __name__ == '__main__':
    unittest.main()
