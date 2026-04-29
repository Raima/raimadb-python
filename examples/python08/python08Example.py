#!/usr/bin/env python3
"""python08Example: Multiple database handles and a union database.

Builds upon python02Example. Mirrors core08Example_main.c.

The concepts introduced in this example are:

- Using more than one database handle
- Union of databases
- Thread safety

The schema is the same as python02. We declare an array of database
names: ``python08-1``, ``python08-2``, ``python08-3`` are three
separate databases; ``"python08-1|python08-2|python08-3"`` (the
three names joined by vertical bars) names the *union* of the three.

In ``do_work()`` we drop each individual database — a union database
can't be dropped directly because a union is a view sitting on top
of the underlying databases. (In C, calling ``rdm_tfsDropDatabase()``
on a union name returns ``eINVFORUNION``, which is ignored.)

In ``do_work_with_tfs_handle()`` we open each database, insert the
same three rows ("Hello", "World", "Andromeda") into each — not a
realistic workload but useful here for demonstrating that the
union contains rows from all three — and then open the union
database ``READONLY`` and read it. A union database is *always*
read-only: inserts and updates must be performed against the
underlying databases. As soon as those underlying databases are
updated (and the transactions committed), the union reflects the
changes. Make sure to commit on the underlying databases before
starting a read transaction on the union.

Applications that use a union typically don't need to know they
are using one — they treat it as a regular (read-only) database.

The creation/insert phase and the read phase are deliberately in
separate loops to underline that each underlying database is
independent: each could be operated on by a different thread or
even a different process. **Do not** operate on a single database
handle from multiple threads simultaneously.
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

DB_NAMES = ["python08-1", "python08-2", "python08-3"]
UNION_NAME = "|".join(DB_NAMES)

SCHEMA = """
create table info
(
    message char(50) primary key
);
"""


def read_rows(db, label):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRowsByKey("INFO", "MESSAGE")
    if rc != Status.Okay:
        trans.end()
        return rc
    print("Database: {}".format(label))
    status = cursor.moveToFirst()
    while status == Status.Okay:
        print("\t{}".format(cursor.MESSAGE))
        status = cursor.moveToNext()
    cursor.free()
    trans.end()
    if status not in (Status.Okay, Status.EndOfCursor):
        return status
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


def populate_one(tfs, name):
    db = tfs.allocDatabase()
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        rc = db.open(name, OpenMode.SHARED)
        if rc == Status.Okay:
            rc = write_rows(db)
            if rc == Status.Okay:
                rc = read_rows(db, name)
    db.free()
    return rc


def read_union(tfs):
    db = tfs.allocDatabase()
    rc = db.open(UNION_NAME, OpenMode.READONLY)
    if rc == Status.Okay:
        rc = read_rows(db, UNION_NAME)
    else:
        print("Failed to open union database {}".format(UNION_NAME))
    db.free()
    return rc


def do_work_with_tfs_handle(tfs):
    for name in DB_NAMES:
        rc = populate_one(tfs, name)
        if rc != Status.Okay:
            return rc
    return read_union(tfs)


def do_work():
    tfs = allocTfs()
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    for name in DB_NAMES:
        try:
            tfs.dropDatabase(name)
        except ErrorNoDB:
            pass
    rc = do_work_with_tfs_handle(tfs)
    tfs.free()
    return rc


def main(argv=None):
    return 0 if do_work() == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
