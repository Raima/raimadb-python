#!/usr/bin/env python3
"""Shared test base class for dbapi tests."""

import unittest
import warnings

from rdm.rdmapi import allocTfs
from rdm.types import OpenMode
from rdm.exceptions import ErrorNoDB, ErrorInvFcnSeq, ErrorDbOpened
from rdm.retcodetypes import Status


class DbTestBase(unittest.TestCase):
    """
    Base class that opens a fresh database in setUp and tears it down
    afterwards. Subclasses must define:
      - DB_NAME : str  — unique database name for this test class
      - SCHEMA  : str  — DDL string passed to setCatalog()
    """

    DB_NAME: str = ""
    SCHEMA: str = ""

    def setUp(self):
        self.tfs = allocTfs()
        status = self.tfs.initialize()
        self.assertEqual(status, Status.Okay, "Failed to initialize TFS")
        try:
            self.tfs.dropDatabase(self.DB_NAME)
        except ErrorNoDB:
            pass
        self.db = self.tfs.allocDatabase()
        status = self.db.setCatalog(self.SCHEMA)
        self.assertEqual(status, Status.Okay, "Failed to set catalog")
        status = self.db.open(self.DB_NAME, OpenMode.SHARED)
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
            self.tfs.dropDatabase(self.DB_NAME)
        except ErrorInvFcnSeq:
            fresh = allocTfs()
            fresh.initialize()
            fresh.dropDatabase(self.DB_NAME)
            fresh.free()
        except ErrorDbOpened as e:
            warnings.warn(f"GC may have prevented implicit close: {e}")
        except ErrorNoDB:
            pass
        if self.tfs is not None:
            try:
                status = self.tfs.free()
                self.assertEqual(status, Status.Okay, "Failed to free TFS")
            except ErrorInvFcnSeq:
                pass
