#!/usr/bin/env python3
"""python05Example: Network model — one-to-many navigation via a set cursor.

Builds upon python04Example. Mirrors core05Example_main.c.

The concept introduced in this example is:

- Network model using a set cursor to iterate over a one-to-many
  relationship

This example uses the same schema and the same network-model
approach as python04, but navigates in the *opposite* direction.
python04 walked from each member row up to its owner; here we walk
from an owner row down to all of its members via
``cursor.getMemberRows(reference)`` and iterate over the resulting
*set cursor*.

To make the one-to-many relationship visible we insert three
member rows (``"World"``, ``"Andromeda"``, ``"M31"``) all linked
to the same owner (``"Hello"``). The reading loop iterates
unconditionally and would handle any number of members.

The only significant code change from python04 is in
``read_some_rows()``.

Python adaptation note: calling ``getMemberRows(ref)`` on an owner
cursor invalidates that owner cursor's row position — read any
owner column values you need into local variables *before* calling
``getMemberRows``, otherwise reading them afterwards raises
``IndexError``.
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
    """Move to the last PRIMARY row, then walk its SECONDARY members."""
    rc, trans = db.startRead()
    if rc != Status.Okay:
        print("rdm_dbStartRead failed")
        return rc
    rc, prim = db.getRows("PRIMARY")
    if rc != Status.Okay:
        print("rdm_dbGetRows on PRIMARY failed")
        trans.end()
        return rc
    status = prim.moveToLast()
    if status != Status.Okay:
        print("moveToLast on PRIMARY failed")
        prim.free()
        trans.end()
        return status
    # Snapshot the owner's INTERJECTION before getMemberRows, which
    # invalidates prim's at_row state.
    interjection = prim.INTERJECTION
    rc2, members = prim.getMemberRows(REF)
    if rc2 != Status.Okay:
        print("getMemberRows failed")
        prim.free()
        trans.end()
        return rc2
    while True:
        status = members.moveToNext()
        if status == Status.EndOfCursor:
            break
        if status != Status.Okay:
            print("moveToNext on SECONDARY failed")
            members.free()
            prim.free()
            trans.end()
            return status
        print("{} {}!".format(interjection, members.ENTITY))
    members.free()
    prim.free()
    trans.end()
    return Status.Okay


def write_rows(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    rc, hi = db.insertRow("PRIMARY", INTERJECTION="Hi")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    rc, hello = db.insertRow("PRIMARY", INTERJECTION="Hello")
    if rc != Status.Okay:
        trans.endRollback()
        return rc
    for entity in ("World", "Andromeda", "M31"):
        rc, sec = db.insertRow("SECONDARY", ENTITY=entity)
        if rc != Status.Okay:
            trans.endRollback()
            return rc
        rc = sec.linkRow(REF, hello)
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
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open("python05", OpenMode.SHARED)
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
        tfs.dropDatabase("python05")
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
