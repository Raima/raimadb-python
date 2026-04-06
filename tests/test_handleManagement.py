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
import warnings

class TestHandleManagement(unittest.TestCase):
    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay, "Failed to initialize TFS")
        try:
            self.tfs.dropDatabase("handle_test")
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog("""
            create table test_table (id int primary key);
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog")
        status = self.db.open("handle_test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        if self.db is not None:
            try:
                status = self.db.free()
                self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
            except ErrorInvFcnSeq:
                pass
            except Exception as e:
                self.fail(f"Exception raised during tearDown: {e}")
        try:
            status = self.tfs.dropDatabase("handle_test")
            self.assertEqual(status, Status.Okay, "Failed to drop database")
        except ErrorInvFcnSeq:
            self.tfs = allocTfs()
            self.tfs.initialize()
            self.tfs.dropDatabase("handle_test")
            self.tfs.free()
        except ErrorDbOpened as e:
            warnings.warn(f"The GC may have prevented the database from implicitly being closed: {e}")
        except Exception as e:
            self.fail(f"Exception raised during tearDown: {e}")
        
        if self.tfs is not None:
            try:
                status = self.tfs.free()
                self.assertEqual(status, Status.Okay, "Failed to free TFS")
            except ErrorInvFcnSeq:
                pass
            except Exception as e:
                self.fail(f"Exception raised during tearDown: {e}")
        

    def test_free_tfs_then_use_db(self):
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay)
        with self.assertRaises(ErrorInvFcnSeq):  # Expect error due to invalidated handle
            self.db.startUpdate()

    def test_free_db_then_use_cursor(self):
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        self.assertEqual(status, Status.Okay)
        status = self.db.free()
        self.assertEqual(status, Status.TrAborted)
        with self.assertRaises(Exception):  # Cursor invalidated
            cursor.moveToNext()

    def test_close_db_then_use_cursor(self):
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        self.assertEqual(status, Status.Okay)
        status = self.db.close()
        self.assertEqual(status, Status.TrAborted)
        with self.assertRaises(ErrorInvFcnSeq):
            cursor.moveToNext()

    def test_set_db_to_none_then_use_cursor(self):
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        self.assertEqual(status, Status.Okay)
        # The following may leave the database open because the BC may need to kick in to free the DB object.
        self.db = None  # Set to None, cursor still holds reference
        status = cursor.moveToNext()  # Should still work if cursor holds valid reference
        self.assertEqual(status, Status.EndOfCursor)  # Assuming empty table

    def test_free_tfs_then_set_db_to_none(self):
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay)
        self.db = None  # Should not crash
        # No further operations to test; no segfault is the goal

    def test_close_db_then_set_cursor_to_none(self):
        status, trans = self.db.startRead()
        status, cursor = self.db.getRows("TEST_TABLE")
        status = self.db.close()
        cursor = None  # Should not crash
        # No further operations; stability is key

if __name__ == '__main__':
    unittest.main(verbosity=2)