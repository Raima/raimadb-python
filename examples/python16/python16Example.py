#!/usr/bin/env python3
"""python16Example: Server-side, client-side, embedded, and hybrid TFS.

Builds upon python01Example. Mirrors core16Example_main.c.

The concept introduced in this example is:

- Server-side, client-side, vs. embedded TFS

The schema is the same as python01. The example can be run in four
modes:

- **Client-side TFS** — the application connects to a server-side
  TFS.
- **Server-side TFS** — the application starts a server-side TFS.
- **Embedded TFS** — the application uses an embedded TFS.
- **Hybrid TFS** — the application uses a hybrid TFS that can
  connect to a server-side TFS via a TFS URI.

The TFS type is set via ``tfs.setOption("tfstype", X)`` where ``X``
is one of ``"client"``, ``"server"``, ``"embed"``, or ``"hybrid"``.
This is functionally the same as linking the application against
the corresponding TFS library variant.

With no options the example defaults to ``"client"`` and expects a
running server. The server can be started either by the
``rdm-tfs`` command-line tool or by running another instance of
this example with ``--server``. The client inserts a row, reads it
back, and exits. If no server is running the application fails to
connect.

In ``--server`` mode the TFS listens on tcp/shm. The database is
created with no rows; the server reads in a loop until it observes
a row inserted by a client, then prints it and exits. (Polling the
database like this is not how you'd do it in production — it's
used here for simplicity, since the focus is the TFS modes.)

In ``--hybrid`` mode the TFS type is ``"hybrid"`` and the database
name is given as a TFS URI (``tfs-shm://21553/python16``). The
behaviour is functionally equivalent to client mode, but a hybrid
application can switch between client/server/embedded operation
without being recompiled. Note: hybrid mode requires a document
root — if a server instance is already using the current working
directory as its docroot, a hybrid instance started in the same
directory will fail.

In ``--embed`` mode the TFS code is linked directly into the
application. ``--embed`` is required for embedded environments
where the application cannot connect to or accept connections
from a remote TFS, or where shared-memory transport is not
supported.

``tfs.setOption()`` can also set ``"docroot"``, ``"force_ssl"``,
and ``"use_ssl"``. ``docroot`` defaults to the current working
directory; ``force_ssl`` and ``use_ssl`` are demonstrated in
python17.

The automated test exercises ``--embed`` only, since orchestrating
a separate TFS server is out of scope. The other modes are
runnable manually.
"""
import sys
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
create table info
(
    message char(50) not null
);
"""


def read_a_row(db, tfs_type):
    rc, trans = db.startRead()
    if rc != Status.Okay:
        return rc
    rc, cursor = db.getRows("INFO")
    if rc == Status.Okay:
        status = cursor.moveToFirst()
        if status == Status.Okay:
            print("The row read from the database using {} TFS is: {}".format(
                tfs_type, cursor.MESSAGE))
        elif status == Status.EndOfCursor:
            rc = Status.EndOfCursor
        cursor.free()
    trans.end()
    return rc


def write_a_row(db, tfs_type):
    rc, trans = db.startUpdate()
    if rc != Status.Okay:
        return rc
    rc, _ = db.insertRow(
        "INFO",
        MESSAGE="Hello World! inserted using {} TFS".format(tfs_type),
    )
    if rc == Status.Okay:
        return trans.end()
    trans.endRollback()
    return rc


def do_work_with_db_handle(db, tfs_type):
    rc = Status.Okay
    if tfs_type != "server":
        rc = write_a_row(db, tfs_type)
        if rc != Status.Okay:
            return rc
    # Server mode: keep retrying until a client inserts a row.
    while True:
        rc = read_a_row(db, tfs_type)
        if rc != Status.EndOfCursor:
            break
    return rc


def do_work_with_tfs_handle(tfs, tfs_type):
    db = tfs.allocDatabase()
    rc = db.setCatalog(SCHEMA)
    if rc == Status.Okay:
        if tfs_type == "hybrid":
            rc = db.open("tfs-shm://21553/python16", OpenMode.SHARED)
        else:
            rc = db.open("python16", OpenMode.SHARED)
        if rc == Status.Okay:
            rc = do_work_with_db_handle(db, tfs_type)
    db.free()
    return rc


def do_work(tfs_type):
    tfs = allocTfs()
    rc = tfs.setOption("tfstype", tfs_type)
    if rc != Status.Okay:
        print("rdm_tfsSetOption(tfstype) failed")
        tfs.free()
        return rc
    if tfs_type == "server":
        rc = tfs.setOption("listen", "tcp,shm")
        if rc != Status.Okay:
            print("rdm_tfsSetOption(listen) failed")
            tfs.free()
            return rc
    rc = tfs.initialize()
    if rc != Status.Okay:
        print("rdm_tfsInitialize failed")
        tfs.free()
        return rc
    if tfs_type in ("server", "embed"):
        try:
            tfs.dropDatabase("python16")
        except ErrorNoDB:
            pass
    rc = do_work_with_tfs_handle(tfs, tfs_type)
    tfs.free()
    return rc


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="TFS deployment modes example."
    )
    g = parser.add_mutually_exclusive_group()
    g.add_argument("--embed", "-e", action="store_const", dest="tfs_type", const="embed")
    g.add_argument("--server", "-s", action="store_const", dest="tfs_type", const="server")
    g.add_argument("--client", "-c", action="store_const", dest="tfs_type", const="client")
    g.add_argument("--hybrid", "-y", action="store_const", dest="tfs_type", const="hybrid")
    parser.set_defaults(tfs_type="client")
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    return 0 if do_work(args.tfs_type) == Status.Okay else 1


if __name__ == "__main__":
    sys.exit(main())
