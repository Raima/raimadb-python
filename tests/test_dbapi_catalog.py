#!/usr/bin/env python3
import unittest

from rdm.rdmapi import allocTfs
from rdm.types import OpenMode
from rdm.exceptions import ErrorNoDB
from rdm.retcodetypes import Status

from _helpers import DbTestBase


class TestCompileCatalog(DbTestBase):
    """Tests for compileCatalog / alterCatalog."""

    DB_NAME = "catalog_test"
    SCHEMA = "create table t (id int primary key, val int);"

    def test_alterCatalog_add_column(self):
        """alterCatalog with valid DDL returns Okay."""
        # The Python row class won't reflect the new column in the same session,
        # but the DDL is accepted and committed successfully.
        # TBD: The above stated behavior is a bug and should be fixed;
        # the test should verify that the new column is usable after alterCatalog.
        _, trans = self.db.startSchemaUpdate()
        status = self.db.alterCatalog("alter table t add column extra int;")
        self.assertEqual(status, Status.Okay)
        status = trans.end()
        self.assertEqual(status, Status.Okay)

    def test_alterCatalog_invalid(self):
        """alterCatalog with invalid DDL raises an exception."""
        _, trans = self.db.startSchemaUpdate()
        with self.assertRaises(Exception):
            self.db.alterCatalog("this is not valid ddl !!!;")
        trans.end()


class TestCompileCatalogFreshDb(unittest.TestCase):
    """Tests that use compileCatalog before open()."""

    DB_NAME = "catalog_compile_test"

    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay)
        try:
            self.tfs.dropDatabase(self.DB_NAME)
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()

    def tearDown(self):
        try:
            self.db.free()
        except Exception:
            pass
        try:
            self.tfs.dropDatabase(self.DB_NAME)
        except Exception:
            pass
        try:
            self.tfs.free()
        except Exception:
            pass

    def test_compileCatalog_then_open(self):
        """compileCatalog with valid DDL then open succeeds."""
        status = self.db.compileCatalog(
            "create table person (id int primary key, name char(50));"
        )
        self.assertEqual(status, Status.Okay)
        status = self.db.open(self.DB_NAME, OpenMode.SHARED)
        self.assertEqual(status, Status.Okay)

    def test_setCatalogFromFile_invalid_path(self):
        """setCatalogFromFile with non-existent path raises an exception."""
        with self.assertRaises(Exception):
            self.db.setCatalogFromFile("/nonexistent/path/to/catalog.sdl")

    def test_compileCatalogFromFile_invalid_path(self):
        """compileCatalogFromFile with non-existent path raises an exception."""
        with self.assertRaises(Exception):
            self.db.compileCatalogFromFile("/nonexistent/path/to/schema.sdl")

    def test_loadCatalogFromFile_invalid_path(self):
        """loadCatalogFromFile with non-existent path raises an exception."""
        with self.assertRaises(Exception):
            self.db.loadCatalogFromFile("/nonexistent/path/to/catalog.cat")

    def test_loadCatalog_invalid_data(self):
        """loadCatalog with garbage bytes raises an exception."""
        with self.assertRaises(Exception):
            self.db.loadCatalog(b"this is not a valid binary catalog blob")


if __name__ == '__main__':
    unittest.main()
