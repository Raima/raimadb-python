#!/usr/bin/env python3
import unittest

from rdm.retcodetypes import Status

from _helpers import DbTestBase

# TFS_TYPE enum values (from rdmtfstypes.h)
TFS_TYPE_DEFAULT = 0
TFS_TYPE_EMBED   = 1
TFS_TYPE_CLIENT  = 2
TFS_TYPE_HYBRID  = 3
TFS_TYPE_RDM     = 4
TFS_TYPE_LOCAL   = 5

ALL_TFS_TYPES = {TFS_TYPE_DEFAULT, TFS_TYPE_EMBED, TFS_TYPE_CLIENT,
                 TFS_TYPE_HYBRID, TFS_TYPE_RDM, TFS_TYPE_LOCAL}


class TestDatabaseInfo(DbTestBase):
    DB_NAME = "info_test"
    SCHEMA = "create table t (id int primary key, val int);"

    def setUp(self):
        super().setUp()
        # Pre-populate with one row so info responses are non-trivial
        _, trans = self.db.startUpdate()
        self.db.insertRow("T", ID=1, VAL=42)
        trans.end()

    def test_getInfo_returns_string(self):
        """getInfo with a valid keyword string returns Okay and a non-empty string."""
        # rdm_dbGetInfo accepts a semicolon-delimited key=value query string
        status, info = self.db.getInfo("drawers=true")
        self.assertEqual(status, Status.Okay)
        self.assertIsInstance(info, str)
        self.assertGreater(len(info), 0)

    def test_getInfo_invalid_keyword(self):
        """getInfo with an unknown keyword raises an exception."""
        with self.assertRaises(Exception):
            self.db.getInfo("__nonexistent_info_keyword__")

    def test_getMemoryUsage_structure(self):
        """getMemoryUsage returns Okay and a dict with the four expected keys."""
        status, mem = self.db.getMemoryUsage()
        self.assertEqual(status, Status.Okay)
        for key in ("systemCurr", "systemMax", "userCurr", "userMax"):
            self.assertIn(key, mem, f"Missing key '{key}' in memory usage dict")
            self.assertIsInstance(mem[key], int)
            self.assertGreaterEqual(mem[key], 0)

    def test_getTFS_returns_original_tfs(self):
        """getTFS() returns the same TFS object that created the database."""
        tfs = self.db.getTFS()
        self.assertIs(tfs, self.tfs)

    def test_getTFSType_valid_value(self):
        """getTFSType returns Okay and a valid TFS_TYPE integer."""
        status, tfs_type = self.db.getTFSType()
        self.assertEqual(status, Status.Okay)
        self.assertIn(tfs_type, ALL_TFS_TYPES)

    def test_findPrimaryKeyIdByTableId_returns_positive_id(self):
        """findPrimaryKeyIdByTableId returns Okay and a positive key ID."""
        status, key_id = self.db.findPrimaryKeyIdByTableId("T")
        self.assertEqual(status, Status.Okay)
        self.assertGreater(key_id, 0)

    def test_findPrimaryKeyIdByTableId_invalid_table(self):
        """findPrimaryKeyIdByTableId with unknown table raises an exception."""
        with self.assertRaises(Exception):
            self.db.findPrimaryKeyIdByTableId("NONEXISTENT_TABLE")

    def test_getCertificate_no_crash(self):
        """getCertificate does not crash (embedded TFS may return empty/error)."""
        status, cert = self.db.getCertificate()
        # Embedded TFS has no certificate; accept any status but no Python exception
        self.assertIsInstance(cert, str)


if __name__ == '__main__':
    unittest.main()
