#!/usr/bin/env python3
import unittest

from rdm.retcodetypes import Status

from _helpers import DbTestBase


class TestOptions(DbTestBase):
    DB_NAME = "options_test"
    SCHEMA = "create table t (id int primary key);"

    def test_getOptions_returns_string(self):
        """getOptions returns Okay and a string (may be empty for default config)."""
        status, opts = self.db.getOptions()
        self.assertEqual(status, Status.Okay)
        self.assertIsInstance(opts, str)

    def test_setOptions_getOptions_roundtrip(self):
        """setOption/getOption roundtrip with the 'timeout' key."""
        # 'timeout' is a valid DB-level option that can be changed on an open DB
        status = self.db.setOption("timeout", "30")
        self.assertEqual(status, Status.Okay)
        status, value = self.db.getOption("timeout")
        self.assertEqual(status, Status.Okay)
        self.assertEqual(value, "30")

    def test_getOption_unknown_key_raises(self):
        """getOption with an unknown keyword raises an exception."""
        with self.assertRaises(Exception):
            self.db.getOption("__nonexistent_option_xyz__")

    def test_clearCache_smoke(self):
        """clearCache returns Okay (smoke test — no state to verify)."""
        status, trans = self.db.startUpdate()
        self.assertEqual(status, Status.Okay)
        self.db.insertRow("T", ID=1)
        trans.end()
        status = self.db.clearCache()
        self.assertEqual(status, Status.Okay)


if __name__ == '__main__':
    unittest.main()
