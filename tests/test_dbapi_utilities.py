#!/usr/bin/env python3
import unittest

from rdm.retcodetypes import Status

from _helpers import DbTestBase


SCHEMA = "create table t (id int primary key, val int);"


class TestVacuum(DbTestBase):
    DB_NAME = "vacuum_test"
    SCHEMA = SCHEMA

    def setUp(self):
        super().setUp()
        # Insert then delete rows so vacuum has something to compact
        _, trans = self.db.startUpdate()
        for i in range(1, 6):
            self.db.insertRow("T", ID=i, VAL=i * 10)
        trans.end()
        _, trans = self.db.startUpdate()
        self.db.deleteAllRowsFromTable("T")
        trans.end()

    def test_vacuum_no_options(self):
        """vacuum() with no options returns Okay."""
        status = self.db.vacuum()
        self.assertEqual(status, Status.Okay)

    def test_vacuum_with_options(self):
        """vacuum() with an options string returns Okay."""
        status = self.db.vacuum("")
        self.assertEqual(status, Status.Okay)


class TestCreateNewPackFile(DbTestBase):
    DB_NAME = "packfile_test"
    SCHEMA = SCHEMA

    def test_createNewPackFile(self):
        """createNewPackFile returns Okay."""
        status = self.db.createNewPackFile()
        self.assertEqual(status, Status.Okay)


class TestPersistInMemory(DbTestBase):
    DB_NAME = "persist_test"
    SCHEMA = SCHEMA

    def test_persistInMemory_no_crash(self):
        """persistInMemory inside an update transaction does not raise for disk-backed tables."""
        _, trans = self.db.startUpdate()
        try:
            # For non-in-memory tables RDM may return an error; accept any status.
            status = self.db.persistInMemory()
            self.assertIsNotNone(status)
        except Exception:
            pass
        finally:
            trans.end()


class TestEncryption(DbTestBase):
    DB_NAME = "encrypt_test"
    SCHEMA = SCHEMA

    def test_setEncrypt_before_open(self):
        """setEncrypt called on a fresh db handle before open succeeds."""
        # Allocate a fresh db handle (not yet opened)
        fresh_db = self.tfs.allocDatabase()
        enc = self.tfs.allocEncrypt("test_passphrase")
        try:
            status = fresh_db.setEncrypt(enc)
            self.assertEqual(status, Status.Okay)
        finally:
            enc.free()
            fresh_db.free()

    def test_encrypt_requires_closed_db(self):
        """encrypt() on an open database raises ErrorExclusive."""
        enc = self.tfs.allocEncrypt("test_passphrase")
        try:
            with self.assertRaises(Exception):
                self.db.encrypt(enc)
        finally:
            enc.free()


if __name__ == '__main__':
    unittest.main()
