#!/usr/bin/env python3
"""python04Example: Network model — many-to-one navigation.

Builds upon python03Example. Mirrors core04Example_main.c.

The concept introduced in this example is:

- Network model instead of the relational model

This example performs the same function as python03 but uses the
network model rather than the relational model. The network model
is a more direct, lower-level way of interacting with the database;
the relational model can be viewed as a higher-level layer built on
top of it. We won't argue which is better — we'll just show how to
use the network model in a way that is functionally equivalent to
the relational version in python03.

In RaimaDB the network model means calling API functions to create
and remove links between rows, follow links from member rows to
their owner, or from an owner row to its members. The schema is
identical to python03's: an owner-member relationship described in
SDL as a foreign reference. The referencing table is the *member*
table and the referenced table is the *owner*. In the simplest
case — used here — the owner has a primary key referenced by a
foreign key on the member. RaimaDB also supports composite primary
and foreign keys, and references to non-primary indexes.

The code differences from python03 are minimal and live in
``write_rows()`` and ``read_some_rows()``. Instead of working with
row ids, we use the cursor to link rows and follow relationships
with ``cursor.linkRow(reference, owner)`` and
``cursor.getOwnerRow(reference)``. The reference id used here is
``"SECONDARY_ID"`` — auto-generated from the foreign key column as
``"<MEMBER_TABLE>_<FK_COLUMN>"``.

Python adaptation note: ``getOwnerRow()`` returns a cursor that is
not yet positioned on a row — call ``owner.moveToFirst()`` (or
equivalent) before reading column attributes, otherwise attribute
access raises ``IndexError``.
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

REF = "SECONDARY_ID"
SCHEMA = """
create table "PRIMARY"
(
    id rowid primary key,
    interjection char(50) not null
);

create table secondary
(
    id rowid references "PRIMARY",
    entity char(50) not null
);
"""


def read_rows(db):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        print("rdm_dbStartRead failed")
        return rc
    rc, sec = db.getRows("SECONDARY")
    if rc != Status.Okay:
        print("rdm_dbGetRows on SECONDARY failed")
        trans.end()
        return rc
    while True:
        status = sec.moveToNext()
        if status == Status.EndOfCursor:
            break
        if status != Status.Okay:
            print("moveToNext on SECONDARY failed")
            sec.free()
            trans.end()
            return status
        # Follow the network-model link back to the PRIMARY (owner) row.
        rc2, prim = sec.getOwnerRow(REF)
        if rc2 != Status.Okay:
            print("rdm_cursorGetOwnerRow failed")
            sec.free()
            trans.end()
            return rc2
        # The returned owner cursor is not yet positioned; reposition it.
        prim.moveToFirst()
        print("{} {}!".format(prim.INTERJECTION, sec.ENTITY))
        prim.free()
    sec.free()
    trans.end()
    return Status.Okay


def write_rows(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        print("rdm_dbStartUpdate failed")
        return rc
    rc, hi = db.insertRow("PRIMARY", INTERJECTION="Hi")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    rc, hello = db.insertRow("PRIMARY", INTERJECTION="Hello")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    # Insert SECONDARY rows without setting the FK column, then link them
    # to their owners via the network-model reference.
    rc, world = db.insertRow("SECONDARY", ENTITY="World")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    rc = world.linkRow(REF, hello)
    if rc != Status.Okay:
        print("linkRow failed for 'World'")
        trans.endRollback()
        return rc
    rc, andromeda = db.insertRow("SECONDARY", ENTITY="Andromeda")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    rc = andromeda.linkRow(REF, hi)
    if rc != Status.Okay:
        print("linkRow failed for 'Andromeda'")
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
        rc = db.open("python04", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db)
        else:
            print("rdm_dbOpen failed")
    else:
        print("rdm_dbSetCatalog failed")
    db.free()
    return rc


def do_work():
    tfs = allocTfs()
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    try:
        tfs.dropDatabase("python04")
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
