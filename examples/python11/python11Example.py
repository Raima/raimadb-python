#!/usr/bin/env python3
"""python11Example: Encrypted database.

Builds upon python01Example. Mirrors core11Example_main.c.

The concept introduced in this example is:

- Encrypted databases

This example does the same work as python01 but encrypts the
database rather than persisting plain-text. In
``do_work_with_tfs_handle()`` we allocate an encryption handle from
the TFS using the algorithm/password string ``"XOR:testing"`` (in
the Python bindings the algorithm prefix is part of the passcode
string) and associate it with the database via ``db.setEncrypt()``
before opening. The database is created encrypted with that handle.

If multiple encryption handles are allocated, the most recently
created one (at the time the database handle was created) — or the
one explicitly assigned with ``db.setEncrypt()`` — is used. To
*open* an encrypted database, at least one encryption handle with
the same algorithm and password used to encrypt it must be
available. Multiple handles allow a union of databases where each
underlying database has its own encryption.

If an *existing* database is unencrypted, simply allocating an
encryption handle won't encrypt it; ``db.encrypt(handle)`` is used
to encrypt an existing closed database.

Other applications must use the same algorithm and password to
access the database. You can verify the database is encrypted by,
for example, running ``rdm-export`` without ``--enc`` — it will
fail with ``eINVENCRYPT: Invalid encryption key``.

XOR is **not** a secure algorithm. It is used here for
demonstration purposes only and to avoid US export restrictions.

When encryption is in use, each table is encrypted separately —
so individual tables can be encrypted or not. Changing the
password does not require re-encrypting the table data: only the
per-table keys are re-encrypted with the new password. If the old
password has been compromised, however, the database should be
fully re-encrypted.
"""
import sys
from rdm import *
from rdm.tfsapi import *
from rdm.dbapi import *
from rdm.cursorapi import *
from rdm.rdmapi import *
from rdm.types import *
from rdm.exceptions import *
from rdm.retcodetypes import *

SCHEMA = """
create table info
(
    message char(50) not null
);
"""


def read_a_row(db):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRows("INFO")
    if rc == Status.Okay:
        if cursor.moveToFirst() == Status.Okay:
            print("The row read from the database is: {}".format(cursor.MESSAGE))
        cursor.free()
    trans.end()
    return rc


def write_a_row(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    rc, _ = db.insertRow("INFO", MESSAGE="Hello World!")
    if rc == Status.Okay:
        return trans.end()
    trans.endRollback()
    return rc


def do_work_with_db_handle(db):
    rc = write_a_row(db)
    if rc == Status.Okay:
        rc = read_a_row(db)
    return rc


def do_work_with_tfs_handle(tfs):
    enc = tfs.allocEncrypt("XOR:testing")
    db = tfs.allocDatabase()
    rc = db.setEncrypt(enc)
    if rc != Status.Okay:
        print("rdm_dbSetEncrypt failed")
        db.free()
        return rc
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open("python11", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db)
    db.free()
    return rc


def do_work():
    tfs = allocTfs()
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    try:
        tfs.dropDatabase("python11")
        print("The database was dropped")
    except ErrorNoDB:
        print("The database does not exist")
    rc = do_work_with_tfs_handle(tfs)
    tfs.free()
    return rc


def main(argv=None):
    return 0 if do_work() == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
