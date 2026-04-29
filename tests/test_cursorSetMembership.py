#!/usr/bin/env python3
"""Tests for cursor set-membership methods: linkRow, relinkRow, unlinkRow,
addMember, removeMember, hasMembers, hasOwner, getMemberCount, getOwnerRowId,
getOwnerTableId."""
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


REF = "MEMBER_OWNER_ID"


class CursorSetMembershipTest(unittest.TestCase):
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
            create table OWNER (
                ID int primary key not null,
                NAME char(20)
            );
            create table "MEMBER" (
                ID int primary key not null,
                OWNER_ID int,
                NAME char(20),
                foreign key (OWNER_ID) references OWNER(ID)
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

    def insert_owners_and_members(self, owners=2, members_per_owner=3):
        """Insert owners (ids 1..owners) and members linked to them."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        for o in range(1, owners + 1):
            status, _ = self.db.insertRow("OWNER", ID=o, NAME=f"owner{o}")
            self.assertEqual(status, Status.Okay)
        mid = 1
        for o in range(1, owners + 1):
            for _ in range(members_per_owner):
                status, _ = self.db.insertRow(
                    "MEMBER", ID=mid, OWNER_ID=o, NAME=f"m{mid}"
                )
                self.assertEqual(status, Status.Okay)
                mid += 1
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    # ----- link / unlink / relink -----

    def test_linkRow_links_unlinked_member(self):
        # Insert owner; insert member without OWNER_ID; then link
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("OWNER", ID=1, NAME="alpha")
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("MEMBER", ID=10, OWNER_ID=None, NAME="orphan")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        status = owner_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)

        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertFalse(member_cursor.hasOwner(REF))

        status = member_cursor.linkRow(REF, owner_cursor)
        self.assertEqual(status, Status.Okay)
        self.assertTrue(member_cursor.hasOwner(REF))
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_addMember_via_set_cursor(self):
        # Owner exists, plus an unlinked member; use set-cursor.addMember().
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("OWNER", ID=1, NAME="alpha")
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("MEMBER", ID=10, OWNER_ID=None, NAME="orphan")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        status = owner_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)

        status, members_set = owner_cursor.getMemberRows(REF)
        self.assertEqual(status, Status.Okay)
        self.assertEqual(members_set.getCount(), 0)

        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)

        status = members_set.addMember(member_cursor)
        self.assertEqual(status, Status.Okay)

        status = trans.end()
        self.assertEqual(status, Status.Okay)

        # Verify
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        status = owner_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(owner_cursor.getMemberCount(REF), 1)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_unlinkRow(self):
        self.insert_owners_and_members(owners=1, members_per_owner=2)
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertTrue(member_cursor.hasOwner(REF))
        status = member_cursor.unlinkRow(REF)
        self.assertEqual(status, Status.Okay)
        self.assertFalse(member_cursor.hasOwner(REF))
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_removeMember(self):
        self.insert_owners_and_members(owners=1, members_per_owner=3)
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        status = owner_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(owner_cursor.getMemberCount(REF), 3)

        status, members_set = owner_cursor.getMemberRows(REF)
        self.assertEqual(status, Status.Okay)
        status = members_set.moveToFirst()
        self.assertEqual(status, Status.Okay)
        status = members_set.removeMember()
        self.assertEqual(status, Status.Okay)

        self.assertEqual(owner_cursor.getMemberCount(REF), 2)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_relinkRow(self):
        # Two owners; move member from owner1 to owner2.
        self.insert_owners_and_members(owners=2, members_per_owner=1)
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)

        status, owners = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)

        # Locate owner with ID=2
        status = owners.moveToFirst()
        self.assertEqual(status, Status.Okay)
        while owners.ID != 2:
            status = owners.moveToNext()
            self.assertEqual(status, Status.Okay)
        owner2 = owners

        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        original_owner_id = member_cursor.OWNER_ID
        self.assertEqual(original_owner_id, 1)

        status = member_cursor.relinkRow(REF, owner2)
        self.assertEqual(status, Status.Okay)
        # Re-read row
        status, m2 = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = m2.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(m2.OWNER_ID, 2)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    # ----- inspection -----

    def test_hasMembers(self):
        self.insert_owners_and_members(owners=2, members_per_owner=2)
        # Insert an extra owner with no members
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("OWNER", ID=99, NAME="empty")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)

        seen = {}
        status = owner_cursor.moveToFirst()
        while status == Status.Okay:
            seen[owner_cursor.ID] = owner_cursor.hasMembers(REF)
            status = owner_cursor.moveToNext()
        self.assertTrue(seen[1])
        self.assertTrue(seen[2])
        self.assertFalse(seen[99])
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_hasOwner(self):
        self.insert_owners_and_members(owners=1, members_per_owner=1)
        # Insert orphan
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        status, _ = self.db.insertRow("MEMBER", ID=99, OWNER_ID=None, NAME="orphan")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        seen = {}
        status = member_cursor.moveToFirst()
        while status == Status.Okay:
            seen[member_cursor.ID] = member_cursor.hasOwner(REF)
            status = member_cursor.moveToNext()
        self.assertTrue(seen[1])
        self.assertFalse(seen[99])
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getMemberCount(self):
        self.insert_owners_and_members(owners=2, members_per_owner=3)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        status = owner_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(owner_cursor.getMemberCount(REF), 3)
        status = owner_cursor.moveToNext()
        self.assertEqual(status, Status.Okay)
        self.assertEqual(owner_cursor.getMemberCount(REF), 3)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getOwnerTableId_matches_owner_table(self):
        self.insert_owners_and_members(owners=1, members_per_owner=1)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        owner_table_id = member_cursor.getOwnerTableId(REF)

        status, owner_cursor = self.db.getRows("OWNER")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(owner_table_id, owner_cursor.getTableId())
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_getOwnerRowId_raises_without_rowid_column(self):
        # OWNER table has no rowid column; getOwnerRowId should raise.
        self.insert_owners_and_members(owners=1, members_per_owner=1)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        with self.assertRaises(ErrorTableNoRowId):
            member_cursor.getOwnerRowId(REF)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_invalid_reference_name_raises(self):
        self.insert_owners_and_members(owners=1, members_per_owner=1)
        status, trans = self.db.startRead()
        self.assertEqual(status, Status.Okay)
        status, member_cursor = self.db.getRows("MEMBER")
        self.assertEqual(status, Status.Okay)
        status = member_cursor.moveToFirst()
        self.assertEqual(status, Status.Okay)
        with self.assertRaises(Exception):
            member_cursor.hasOwner("NON_EXISTENT_REF")
        status = trans.end()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
