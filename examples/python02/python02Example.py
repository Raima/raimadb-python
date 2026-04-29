#!/usr/bin/env python3
"""python02Example: Primary key columns and cursor navigation.

Builds upon python01Example. Mirrors core02Example_main.c. Read
python01 first to familiarise yourself with the main concepts.

The new concepts introduced in this example are:

- Primary key columns
- Cursor navigation
    - Moving the cursor to a key position that doesn't point to any row
    - Navigating from a position between key values to the next row

The schema is similar to python01: the table ``INFO`` has a single
column ``MESSAGE``, also declared as the primary key.

We insert three rows in ``write_rows()``: "Hello", "World", and
"Andromeda". We then read them through a cursor in
``read_some_rows()``. The cursor walks the table in *primary-key
order*, even though the rows were inserted in a different order.

We do not retrieve all rows — only those that come after the key
"Betelgeuse". The cursor is moved to that key with
``cursor.moveToKey(...)``. There is no row at that key, so the call
returns ``Status.NotFound``, which we ignore. From this position we
could navigate backwards to the first row, but instead we walk
forward via ``moveToNext()`` until ``Status.EndOfCursor`` is
returned. ``EndOfCursor`` is a special position *after* the last
row — there are no more rows ahead, but you could still navigate
backwards from there.
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
    """Move to a non-existent key, then iterate forward printing each row."""
    rc, trans = db.startRead()
    if rc != Status.Okay:
        print("rdm_dbStartRead failed to start a read transaction")
        return rc
    rc, cursor = db.getRowsByKey("INFO", "MESSAGE")
    if rc != Status.Okay:
        print("rdm_dbGetRowsByKey failed to associate a cursor with a table")
        trans.end()
        return rc
    # Try to move to a non-existent key. NotFound positions the cursor
    # between rows; subsequent moveToNext walks the rest of the table.
    status = cursor.moveToKey("MESSAGE", MESSAGE="Betelgeuse")
    if status not in (Status.Okay, Status.NotFound):
        print("rdm_cursorMoveToKey failed unexpectedly")
        cursor.free()
        trans.end()
        return status
    while True:
        status = cursor.moveToNext()
        if status == Status.EndOfCursor:
            break
        if status != Status.Okay:
            print("rdm_cursorMoveToNext failed")
            cursor.free()
            trans.end()
            return status
        print("The row read from the database is: {}".format(cursor.MESSAGE))
    cursor.free()
    trans.end()
    return Status.Okay


def write_rows(db):
    """Insert three rows: 'Hello', 'World', 'Andromeda'."""
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        print("rdm_dbStartUpdate failed to start an update transaction")
        return rc
    for msg in ("Hello", "World", "Andromeda"):
        rc, _ = db.insertRow("INFO", MESSAGE=msg)
        if rc != Status.Okay:
            print("rdm_dbInsertRow failed to insert {!r}".format(msg))
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
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open("python02", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db)
        else:
            print("rdm_dbOpen failed to open the database 'python02'")
    else:
        print("rdm_dbSetCatalog failed to associate a catalog with the database handle")
    db.free()
    return rc


def do_work():
    tfs = allocTfs()
    rc = tfs.initialize()
    if rc != Status.Okay:
        print("rdm_tfsInitialize failed to initialize the TFS handle")
        tfs.free()
        return rc
    try:
        tfs.dropDatabase("python02")
        print("The database was dropped")
    except ErrorNoDB:
        print("The database does not exist")
    rc = do_work_with_tfs_handle(tfs)
    tfs.free()
    return rc


def main(argv=None):
    rc = do_work()
    return 0 if rc == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
