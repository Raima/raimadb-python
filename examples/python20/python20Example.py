#!/usr/bin/env python3
"""python20Example: Continuous reader/writer loop (replication building block).

Builds upon python16Example. Mirrors core20Example_main.c. The
schema is intentionally minimal: a single table ``info`` with one
``uint64`` primary key column ``myNumber``. The point of this
example is **not** to introduce new database concepts but to serve
as a building block for demonstrating replication and hot backup
(see https://raima.com/replication-and-hot-backup/).

Like python16 the example can run in client / server / embedded
modes via ``tfs.setOption("tfstype", X)``.

The program enters a loop that performs writes and/or reads
depending on the options:

- Default: both write and read each iteration.
- ``--reader-only`` / ``-r``: read only.
- ``--writer-only`` / ``-w``: write only.
- ``--iterations N`` / ``-i N``: stop after N iterations (the C
  default of 0 means "run forever").
- ``--sleep-ms MS`` / ``-m MS``: sleep MS milliseconds between
  iterations (default 1000).

The writer finds the last (i.e. largest-keyed) row, increments its
value, and inserts the next row. The reader simply prints the
last row's value. In a real workload you would replace the loop
body with something more meaningful; the previous examples in the
series demonstrate many of the building blocks for that.

Python adaptation note: the C example uses ``rdm_dbStartSnapshot()``
for reads (snapshot transactions are the only kind allowed at the
receiving end of a replication setup). The current Python
bindings have a known issue where cursor navigation after
``db.startSnapshot()`` raises ``ErrorNotLocked``; this example
uses ``db.startRead()`` instead.
"""
import sys
import time
import argparse
from rdm import *
from rdm.tfsapi import *
from rdm.dbapi import *
from rdm.cursorapi import *
from rdm.rdmapi import *
from rdm.types import *
from rdm.exceptions import *
from rdm.retcodetypes import *

SCHEMA = """
create table info (
    myNumber uint64 primary key
);
"""


def read_last_row(db):
    rc, trans = db.startSnapshot()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRows("INFO")
    if rc == Status.Okay:
        status = cursor.moveToLast()
        if status == Status.EndOfCursor:
            print("No rows to read")
        elif status == Status.Okay:
            print("Read:     {}".format(cursor.MYNUMBER))
        else:
            rc = status
        cursor.free()
    trans.end()
    return rc


def insert_row(db):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    next_number = 0
    rc, cursor = db.getRows("INFO")
    if rc == Status.Okay:
        status = cursor.moveToLast()
        if status == Status.Okay:
            next_number = cursor.MYNUMBER + 1
        elif status != Status.EndOfCursor:
            rc = status
        cursor.free()
    if rc == Status.Okay:
        rc, _ = db.insertRow("INFO", MYNUMBER=next_number)
    if rc == Status.Okay:
        print("Inserted: {}".format(next_number))
        return trans.end()
    trans.endRollback()
    return rc


def do_operations(db, iterations, sleep_ms, writing, reading):
    rc = Status.Okay
    iteration = 0
    while rc == Status.Okay and (iterations == 0 or iteration < iterations):
        if writing:
            rc = insert_row(db)
            if rc != Status.Okay:
                break
            time.sleep(sleep_ms / 1000.0)
        if reading:
            rc = read_last_row(db)
            if rc != Status.Okay:
                break
            time.sleep(sleep_ms / 1000.0)
        iteration += 1
    return rc


def do_work_with_db_handle(db, iterations, sleep_ms, writing, reading):
    return do_operations(db, iterations, sleep_ms, writing, reading)


def do_work_with_tfs_handle(tfs, tfs_type, iterations, sleep_ms, writing, reading):
    db = tfs.allocDatabase()
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        mode = OpenMode.SHARED if writing else OpenMode.READONLY
        rc = db.open("python20", mode)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db, iterations, sleep_ms, writing, reading)
    db.free()
    return rc


def do_work(tfs_type, iterations, sleep_ms, writing, reading):
    tfs = allocTfs()
    rc = tfs.setOption("tfstype", tfs_type)
    if rc != Status.Okay:
        tfs.free()
        return rc
    if tfs_type == "server":
        rc = tfs.setOption("listen", "tcp,shm")
        if rc != Status.Okay:
            tfs.free()
            return rc
    rc = tfs.initialize()
    if rc != Status.Okay:
        tfs.free()
        return rc
    if tfs_type == "embed":
        try:
            tfs.dropDatabase("python20")
        except ErrorNoDB:
            pass
    rc = do_work_with_tfs_handle(tfs, tfs_type, iterations, sleep_ms, writing, reading)
    tfs.free()
    return rc


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="Continuous reader/writer loop example."
    )
    parser.add_argument("-r", "--reader-only", action="store_true")
    parser.add_argument("-w", "--writer-only", action="store_true")
    parser.add_argument("-m", "--sleep-ms", type=int, default=1000)
    parser.add_argument("-i", "--iterations", type=int, default=0)
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--embed", action="store_const", dest="tfs_type", const="embed")
    g.add_argument("--server", action="store_const", dest="tfs_type", const="server")
    g.add_argument("--client", action="store_const", dest="tfs_type", const="client")
    parser.set_defaults(tfs_type="embed")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    writing = not args.reader_only
    reading = not args.writer_only
    rc = do_work(
        args.tfs_type, args.iterations, args.sleep_ms, writing, reading,
    )
    return 0 if rc == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
