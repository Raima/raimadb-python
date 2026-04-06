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

# This is the same test as setTest except that we here are using an iterator to retrieve the rows.
# This test therefor, has no test for the getSiblingRowsAtPosition method
# since an iterator always starts from the first row.
class SetIteratorTest(unittest.TestCase):
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
            create table OWNER (
                ID int primary key not null,
                STR char(20)
            );
            create table "MEMBER" (
                ID int primary key not null,
                OWNER_ID int,
                STR char(20),
                foreign key (OWNER_ID) references OWNER(ID)
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
        owners = [
            (1, "owner1"),
            (2, "owner2"),
            (3, "owner3"),
            (4, "owner4"),
            (5, "owner5")
        ]
        for oid, ostr in owners:
            status, _ = self.db.insertRow("OWNER", ID=oid, STR=ostr)
            self.assertEqual(status, Status.Okay, f"Failed to insert row with ID={oid}")
        rows = [
            (1, "member1"),
            (1, "member2"),
            (1, "member3"),
            (2, "member4"),
            (3, "member5"),
            (4, "member6"),
            (5, "member7")
        ]
        for i, (oid, str_val) in enumerate(rows, 1):
            status, _ = self.db.insertRow("MEMBER", ID=i, OWNER_ID=oid, STR=str_val)
            self.assertEqual(status, Status.Okay, f"Failed to insert row with ID={i}")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def verify_rows(self, cursor:RdmCursor, columns:list, expected:list):
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        retrieved = []
        for _ in cursor:
            row = tuple(getattr(cursor, col) for col in columns)
            retrieved.append(row)
        self.assertEqual(retrieved, expected, "Rows not retrieved in expected order")
        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def verify_table_rows(self, table, columns, expected):
        status, cursor = self.db.getRows(table)
        self.assertEqual(status, Status.Okay, "Failed to get rows")
        self.verify_rows(cursor, columns, expected)

    def test_get_member_rows(self):
        self.insert_test_data()
        expected = [
            (1, 1, "member1"),
            (2, 1, "member2"),
            (3, 1, "member3"),
            (4, 2, "member4"),
            (5, 3, "member5"),
            (6, 4, "member6"),
            (7, 5, "member7")]
        self.verify_table_rows("MEMBER", ["ID", "OWNER_ID", "STR"], expected)

    def test_get_owner_rows(self):
        self.insert_test_data()
        expected = [
            (1, "owner1"),
            (2, "owner2"),
            (3, "owner3"),
            (4, "owner4"),
            (5, "owner5")
        ]
        self.verify_table_rows("OWNER", ["ID", "STR"], expected)

    def test_get_members_of_first_owner(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, owner = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay, "Failed to get rows from OWNER")

        status = owner.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first owner")
        status, members = owner.getMemberRows("MEMBER_OWNER_ID")
        #status, members = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay, "Failed to get members of first owner")
        self.verify_rows(members, ["ID", "OWNER_ID", "STR"], [
            (1, 1, "member1"),
            (2, 1, "member2"),
            (3, 1, "member3")
        ])

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_get_owner_of_first_member(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, members = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay, "Failed to get rows from MEMBER")

        status = members.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first member")
        status, owner = members.getOwnerRow("MEMBER_OWNER_ID")
        self.assertEqual(status, Status.Okay, "Failed to get owner of first member")
        self.verify_rows(owner, ["ID", "STR"], [
            (1, "owner1")
        ])

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

    def test_get_sibling_rows_of_first_member(self):
        self.insert_test_data()
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay, "Failed to start read")
        status, members = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay, "Failed to get rows from MEMBER")

        status = members.moveToFirst()
        self.assertEqual(status, Status.Okay, "Failed to move to first member")
        status, siblings = members.getSiblingRows("MEMBER_OWNER_ID")
        self.assertEqual(status, Status.Okay, "Failed to get siblings of first member")
        self.verify_rows(siblings, ["ID", "OWNER_ID", "STR"], [
            (1, 1, "member1"),
            (2, 1, "member2"),
            (3, 1, "member3")
        ])

        status = trans.end()
        self.assertEqual(status, Status.Okay, "Failed to end transaction")

if __name__ == '__main__':
    unittest.main()