#!/usr/bin/env python3
"""python07Example: Opening a database in in-memory mode.

Builds upon python02Example. Mirrors core07Example_main.c.

The concept introduced in this example is:

- Opening a database in in-memory mode

This is done by calling ``db.setOption("storage", "inmemory_volatile")``
in ``do_work_with_tfs_handle()`` just before opening the database.
Everything else is the same as python02 — except we don't drop the
database if it already exists, since a volatile in-memory database
is not stored on disk and disappears when the application exits.

In-memory databases are useful for temporary data, for data that
is not needed after the application closes, and for testing or
development where you want to start with a clean database every
time.

Instead of ``"inmemory_volatile"`` you can use ``"inmemory_persist"``,
``"inmemory_keep"``, or ``"inmemory_load"``:

- ``inmemory_persist`` — loads from disk if the database exists,
  otherwise creates one in memory; persists to disk on close.
- ``inmemory_keep`` — like volatile but keeps the database in
  memory after close (until the host process or remote server
  exits).
- ``inmemory_load`` — loads from disk if it exists, otherwise
  creates one in memory; does *not* auto-persist on close, but
  you can persist explicitly with ``db.persistInMemory()``.

With in-memory databases, ACID semantics are slightly different.
Consistency and isolation within a transaction still hold.
Durability is only guaranteed if the database is persisted to disk
before close, or if it was opened in ``inmemory_persist`` mode and
closed cleanly. Atomicity between clients is preserved within
transaction units, but atomicity with respect to durability is
per-persist: if a persist fails for any reason, the on-disk copy
reverts to its prior consistent state.
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
    message char(50) primary key
);
"""


def read_rows(db):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRowsByKey("INFO", "MESSAGE")
    if rc != Status.Okay:
        trans.end()
        return rc
    status = cursor.moveToKey("MESSAGE", MESSAGE="Betelgeuse")
    if status not in (Status.Okay, Status.NotFound):
        cursor.free()
        trans.end()
        return status
    while True:
        status = cursor.moveToNext()
        if status == Status.EndOfCursor:
            break
        if status != Status.Okay:
            cursor.free()
            trans.end()
            return status
        print("The row read from the database is: {}".format(cursor.MESSAGE))
    cursor.free()
    trans.end()
    return Status.Okay


def write_rows(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    for msg in ("Hello", "World", "Andromeda"):
        rc, _ = db.insertRow("INFO", MESSAGE=msg)
        if rc != Status.Okay:
            trans.endRollback()
            return rc
    return trans.end()


def do_work_with_db_handle(db):
    rc = write_rows(db)
    if rc == Status.Okay:
        rc = read_rows(db)
    return rc


def do_work_with_tfs_handle(tfs):
    db = tfs.allocDatabase()
    # Volatile in-memory storage: nothing is written to disk; the database
    # exists only for the lifetime of this handle.
    rc = db.setOption("storage", "inmemory_volatile")
    if rc != Status.Okay:
        print("rdm_dbSetOption(storage, inmemory_volatile) failed")
        db.free()
        return rc
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open("python07", OpenMode.SHARED)
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
    # No drop call — in-memory volatile databases don't persist.
    rc = do_work_with_tfs_handle(tfs)
    tfs.free()
    return rc


def main(argv=None):
    return 0 if do_work() == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
