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

class TestDatabaseOperations(unittest.TestCase):
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
            create table person1 (
                k1 int primary key,
                k2 int default 22,
                k3 int default 33,
                k4 int default 44 not null,
                k5 int default 55 not null,
                k6 int default 66 not null,
                k7 int,
                k8 int default 88,
                k9 int default 99 not null,
                a int array [10],
                constraint person_k2_k3 unique (k2, k3)
            );
        """)
        self.assertEqual(status, Status.Okay, "Failed to set catalog for database")
        status = self.db.open("cyton-test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

    def tearDown(self):
        status = self.db.free()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to free database")
        with self.assertRaises(ErrorInvFcnSeq):
            self.db.free()
            self.error("Database should not be accessible after free")
        self.tfs.dropDatabase("cyton-test")
        status = self.tfs.free()
        self.assertEqual(status, Status.Okay, "Failed to free TFS")

    def test_insert_and_update(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay, "Failed to start update")
        status, person = self.db.insertRow("PERSON1", K2=222, K8=None, A=[1,2,3,4,5,6,7,8,9,10])
        self.assertEqual(status, Status.Okay, "Failed to insert row")
        self.assertEqual(person.K2, 222)
        self.assertEqual(person.K3, 33)
        status = person.update(K1=111)
        self.assertEqual(status, Status.Okay, "Failed to update row")
        self.assertEqual(person.K1, 111)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def insert_some_data_for_test(self):
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay, "Failed to start update")
        status,self.person = self.db.insertRow("PERSON1", K2=222, K3=33)
        self.assertEqual(status, Status.Okay, "Failed to insert row with unique constraint")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_unique_constraint(self):
        self.insert_some_data_for_test()

        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay, "Failed to start update")
        with self.assertRaises(Exception):
            self.db.insertRow("PERSON1", K2=222, K3=33)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_move_next_previous(self):
        self.insert_some_data_for_test()

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status = self.person.moveToNext()
        self.assertEqual(status, Status.EndOfCursor, "Failed to move to next row")
        status = self.person.moveToPrevious()
        self.assertEqual(status, Status.Okay, "Failed to move to previous row")
        self.assertEqual(self.person.K2, 222)
        self.assertEqual(self.person.K3, 33)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_get_rows(self):
        self.insert_some_data_for_test()

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, person = self.db.getRows("PERSON1")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        status = person.moveToNext()
        self.assertEqual(status, Status.Okay, "Failed to move to next row")
        self.assertEqual(person.K2, 222)
        self.assertEqual(person.K3, 33)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_ropen(self):
        self.insert_some_data_for_test()

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, person = self.db.getRows("PERSON1")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

        status = self.db.close()
        self.assertIn(status, (Status.Okay, Status.TrAborted), "Failed to close database")

        status = self.db.open("cyton-test", OpenMode.SHARED)
        self.assertEqual(status, Status.Okay, "Failed to open database")

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        with self.assertRaises(ErrorInvFcnSeq):
            status = person.moveToNext()
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_read_row_at_before_first_and_after_last(self):
        self.insert_some_data_for_test()

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, person = self.db.getRows("PERSON1")
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        with self.assertRaises(IndexError):
            self.assertEqual(person.K2, 22)
            self.assertEqual(person.K3, 33)
        status = person.moveToNext()
        self.assertEqual(status, Status.Okay, "Failed to move to next row")
        self.assertEqual(person.K2, 222)
        self.assertEqual(person.K3, 33)
        status = person.moveToNext()
        self.assertEqual(status, Status.EndOfCursor, "Failed to move to after last")
        with self.assertRaises(IndexError):
            self.assertEqual(person.K2, 22)
            self.assertEqual(person.K3, 33)
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

if __name__ == '__main__':
    unittest.main()
